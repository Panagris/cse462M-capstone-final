"""
File: convolver_dma.py
Authors: B. Ko, C. Okoye, S. Xiao
"""

import asyncio
import time
from functools import wraps
from typing import Optional
import numpy as np
from pynq import Overlay, DefaultIP, allocate
from accelerator_driver import AcceleratorDriver

# ######################################################################################################################

def get_layer_input_size(layer_index, n_in, P, K, p):
    """
    Calculate the input dimension for a given CNN layer index.

    Parameters:
    - layer_index (int): Index of the CNN layer (0-based)
    - n_in (int): Original input size
    - P (int): Padding per layer
    - K (int): Kernel size per layer
    - p (int): Pooling window size per layer

    Returns:
    - int: Size of the input map to the specified layer
    """
    result = n_in
    for _ in range(layer_index):
        result = (result + 2 * P - K + 1) // p
    return result

# ######################################################################################################################

class Timer:
    def __init__(self, output_file: str):
        self.output_file = output_file

    def __enter__(self):
        self.start_time = time.monotonic()

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.end_time = time.monotonic()
        self.elapsed_time = self.end_time - self.start_time
        with open(f"{self.output_file}", "a") as file:
            file.write(f"{self.elapsed_time}" + "\n")


# ######################################################################################################################

@wraps(allocate)
def allocate_coherent(*args, **kwargs):
    buffer = allocate(*args, **kwargs)
    buffer.coherent = True
    return buffer


# ######################################################################################################################

class Application:
    NUM_IARGS = 1
    NUM_OARGS = 1
    NUM_ISCALARS = 1
    NUM_OSCALARS = 0

    def __init__(self, bit_file: str):
        self.name = bit_file
        self.overlay = None
        self.dma = None
        self.acc: Optional[AcceleratorDriver] = None

    def create_overlay(self):
        try:
            # Ensure there's an event loop in this thread
            try:
                asyncio.get_event_loop()
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)

            self.overlay = Overlay(self.name)
            self.dma = self.overlay.axi_dma_0
            self.acc = self.overlay.axis_accelerator_ada_0
        except Exception as e:
            print(f"Error during overlay creation: {e}")

    def setup_accelerator_adaptor_core(self):
        # Do a soft reset.
        self.acc.soft_reset()

        # Configure the input argument request enable register for 1 input argument.
        self.acc.iarg_rqt_en_reg = (1 << self.NUM_IARGS) - 1

        # Configure the output argument request enable register for 1 output argument.
        self.acc.oarg_rqt_en_reg = (1 << self.NUM_OARGS) - 1

        # Configure the input scalar request enable register for 1 input scalar.
        self.acc.iscalar_rqt_en_reg = (1 << self.NUM_ISCALARS) - 1

        # Configure the output scalar request enable register for 1 output scalar.
        self.acc.oscalar_rqt_en_reg = (1 << self.NUM_OSCALARS) - 1

        # Set the output argument length mode to Hardware.
        self.acc.oarg_length_mode_reg = self.acc.OutputArgumentLengthModeEnum.Hardware

        # Move the output buffer to the next position on every data output on the stream channel.
        self.acc.cmd_reg = 0x00010001

        # Move the input buffer to the next position on every data input on the stream channel.
        self.acc.cmd_reg = 0x00000101

    def convolve_image(self, input_array: np.ndarray) -> np.ndarray:
        print("Entered convolve_image().")
        h, w = input_array.shape
        flat_input = input_array.flatten().astype(np.uint32)
        input_len_bytes = flat_input.size << 2  # input length in bytes

        print(f"The input {input_array}")

        # There are 3 layers, so the output dimension of the 3rd layer is the input dimension of the 4th
        output_layer_index = 4
        padding = 1
        kernel_dim = 3
        pooler_dim = 2

        output_dim = get_layer_input_size(output_layer_index, h, padding, kernel_dim,
                                          pooler_dim)

        output_len_bytes = (output_dim * output_dim) << 2

        # Allocate buffers
        input_buf = allocate_coherent(shape=(1 + flat_input.size,), dtype=np.uint32)
        output_buf = allocate_coherent(shape=(output_len_bytes,), dtype=np.uint32)

        input_buf[0] = input_len_bytes
        input_buf[1:] = flat_input

        self.acc.set_iscalar_data(0, 1)  # Example scalar (e.g., kernel ID)

        print("Starting DMA send/recv transfers.")
        self.dma.sendchannel.transfer(input_buf)
        self.dma.recvchannel.transfer(output_buf)

        print("Accelerator adaptor: execute step.")
        self.acc.execute_step()

        print("Waiting on DMA send channel.")
        self.dma.sendchannel.wait()
        print("Waiting on DMA recv channel.")
        self.dma.recvchannel.wait()
        print("DMA controller transaction complete.")

        convolved = output_buf

        with open("CNN_output_hex.txt", "w") as f:
            f.writelines(f"{val:x}\n" for val in output_buf)

        with open("CNN_output_bin.txt", "w") as f:
            f.writelines(f"{val:032b}\n" for val in output_buf)

        print("Wrote output to CNN_output_hex.txt, CNN_output_bin.txt!")

        # Free buffers
        input_buf.freebuffer()
        output_buf.freebuffer()
        print("Buffers freed. Returning to main...")

        return convolved

    def convolve_image_timed(self, input_array: np.ndarray) -> np.ndarray:
        h, w = input_array.shape
        flat_input = input_array.flatten().astype(np.uint32)
        input_len_bytes = flat_input.size << 2  # input length in bytes

        output_layer_index = 4
        padding_add = 1
        kernel_dim = 3
        pooler_dim = 2

        output_dim = get_layer_input_size(output_layer_index, h, padding_add, kernel_dim,
                                          pooler_dim)

        output_len_bytes = (output_dim * output_dim) << 2

        # Allocate buffers
        input_buf = allocate_coherent(shape=(1 + flat_input.size,), dtype=np.uint32)
        output_buf = allocate_coherent(shape=(output_len_bytes,), dtype=np.uint32)

        input_buf[0] = input_len_bytes
        input_buf[1:] = flat_input

        input_buf.flush()

        self.acc.set_iscalar_data(0, 1)

        self.dma.sendchannel.transfer(input_buf)
        self.dma.recvchannel.transfer(output_buf)

        # Time only the computation.
        with Timer("execution_time.txt"):
            self.acc.execute_step()
            self.dma.sendchannel.wait()
            self.dma.recvchannel.wait()

        # Free buffers
        input_buf.freebuffer()
        output_buf.freebuffer()

        return output_buf