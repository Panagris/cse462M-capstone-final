"""
File: accelerator_driver.py
Author: Dr. Michael Hall, Professor CSE 462M, Washington University
"""
from pynq import Overlay, DefaultIP, allocate
from enum import IntEnum
from itertools import chain
import numpy as np


class AcceleratorDriver(DefaultIP):
    CTRL_REG_ADDR = 0x0000
    STATUS_REG_ADDR = 0x0004
    IARG_RQT_EN_REG_ADDR = 0x0010
    OARG_RQT_EN_REG_ADDR = 0x0014
    CMD_REG_ADDR = 0x0028
    OARG_LENGTH_MODE_REG_ADDR = 0x003C
    ISCALAR_RQT_EN_REG_ADDR = 0x0048
    OSCALAR_RQT_EN_REG_ADDR = 0x004C
    ISCALAR_DATA_REG_BASE_ADDR = 0x0080
    OSCALAR_DATA_REG_BASE_ADDR = 0x00C0
    IARG_STATUS_REG_BASE_ADDR = 0x0100
    OARG_STATUS_REG_BASE_ADDR = 0x0140
    ISCALAR_STATUS_REG_BASE_ADDR = 0x0180
    OSCALAR_STATUS_REG_BASE_ADDR = 0x01C0
    OARG_LENGTH_REG_BASE_ADDR = 0x0200
    OARG_TDEST_REG_BASE_ADDR = 0x0240

    class OutputArgumentLengthModeEnum(IntEnum):
        Hardware: int = 0
        Software: int = 1

    def __init__(self, description):
        super().__init__(description=description)

    bindto = ["xilinx.com:ip:axis_accelerator_adapter:2.1"]

    def _compute_indexed_offset(self, base_addr: int, index: int):
        return base_addr + (index << 2)

    @property
    def ctrl_reg(self):
        """ Control Register (CTRL). Provides soft reset option for the Accelerator Adapter core. """
        return self.read(self.CTRL_REG_ADDR)

    @ctrl_reg.setter
    def ctrl_reg(self, value):
        self.write(self.CTRL_REG_ADDR, value)

    @property
    def status_reg(self):
        """ Status Register (STATUS). Provides current status of accelerator control interface of Accelerator Adaptor
         core. """
        return self.read(self.STATUS_REG_ADDR)

    @status_reg.setter
    def status_reg(self, value):
        self.write(self.STATUS_REG_ADDR, value)

    @property
    def iarg_rqt_en_reg(self):
        """ Input Argument Request Enable Register (IARG_RQT_EN).

        This is used by the Accelerator Adapter core to issue new task execution (ap_start signal) to the accelerator.
        This register enables to select which input arguments is used in the generation of start signal.

        Bits [N-1:0] - IARG_EN - Request enable for input arguments [N-1:0].
        """
        return self.read(self.IARG_RQT_EN_REG_ADDR)

    @iarg_rqt_en_reg.setter
    def iarg_rqt_en_reg(self, value):
        self.write(self.IARG_RQT_EN_REG_ADDR, value)

    @property
    def oarg_rqt_en_reg(self):
        """ Output Argument Request Enable Register (OARG_RQT_EN).

         This is used by the Accelerator Adapter core to issue new task execution (ap_start signal) to the accelerator.

         Bits [N-1:0] - OARG_EN - Request enable for output arguments [N-1:0].
         """
        return self.read(self.OARG_RQT_EN_REG_ADDR)

    @oarg_rqt_en_reg.setter
    def oarg_rqt_en_reg(self, value):
        self.write(self.OARG_RQT_EN_REG_ADDR, value)

    @property
    def cmd_reg(self):
        """ Command Register (COMMAND) """
        return self.read(self.CMD_REG_ADDR)

    @cmd_reg.setter
    def cmd_reg(self, value):
        self.write(self.CMD_REG_ADDR, value)

    @property
    def oarg_length_mode_reg(self):
        """ Output Argument Length Mode Register (OARG_LENGTH_MODE) """
        return self.read(self.OARG_LENGTH_MODE_REG_ADDR)

    @oarg_length_mode_reg.setter
    def oarg_length_mode_reg(self, value):
        if isinstance(value, self.OutputArgumentLengthModeEnum):
            value = value.value
        self.write(self.OARG_LENGTH_MODE_REG_ADDR, value)

    @property
    def iscalar_rqt_en_reg(self):
        """ Input Scalar Request Enable Register (ISCALAR_RQT_EN) """
        return self.read(self.ISCALAR_RQT_EN_REG_ADDR)

    @iscalar_rqt_en_reg.setter
    def iscalar_rqt_en_reg(self, value):
        self.write(self.ISCALAR_RQT_EN_REG_ADDR, value)

    @property
    def oscalar_rqt_en_reg(self):
        """ Output Scalar Request Enable Register (OSCALAR_RQT_EN) """
        return self.read(self.OSCALAR_RQT_EN_REG_ADDR)

    @oscalar_rqt_en_reg.setter
    def oscalar_rqt_en_reg(self, value):
        self.write(self.OSCALAR_RQT_EN_REG_ADDR, value)

    def soft_reset(self):
        """ Soft Reset. Resets adapter core logic. """
        saved = self.ctrl_reg
        self.ctrl_reg = saved | 0x1
        self.ctrl_reg = saved & ~0x1

    def set_iscalar_data(self, n, data):
        """ Input Scalar Write Data Register (ISCALARn_DATA) """
        self.write(self._compute_indexed_offset(self.ISCALAR_DATA_REG_BASE_ADDR, n), data)

    def get_iarg_status_reg(self, n):
        """ Input Buffer Status Register (IARGn_STATUS) """
        return self.read(self._compute_indexed_offset(self.IARG_STATUS_REG_BASE_ADDR, n))

    def get_oarg_status_reg(self, n):
        """ Output Buffer Status Register (OARGn_STATUS) """
        return self.read(self._compute_indexed_offset(self.OARG_STATUS_REG_BASE_ADDR, n))

    def get_iscalar_status_reg(self, n):
        """ Input Scalar Status Register (ISCALARn_STATUS) """
        return self.read(
            self._compute_indexed_offset(self.ISCALAR_STATUS_REG_BASE_ADDR, n))

    def get_oscalar_status_reg(self, n):
        return self.read(
            self._compute_indexed_offset(self.OSCALAR_STATUS_REG_BASE_ADDR, n))

    def set_oarg_length(self, n, length):
        self.write(self._compute_indexed_offset(self.OARG_LENGTH_REG_BASE_ADDR, n),
                   length)

    def get_oarg_tdest(self, n):
        return self.read(self._compute_indexed_offset(self.OARG_TDEST_REG_BASE_ADDR, n))

    def set_oarg_tdest(self, n, data):
        self.write(self._compute_indexed_offset(self.OARG_TDEST_REG_BASE_ADDR, n), data)

    def execute_step(self):
        """ Execute step (Single iteration).

        19:16 OPCODE = 0b010 = Execute step (Single iteration).
        """
        self.cmd_reg = 0x00020000

    def dump_registers(self):
        """ Dump all registers. """
        print("Register Dump:")
        for ri in chain(range(2), range(4, 6), range(10, 11), range(15, 20),
                        range(32, 56), range(64, 72),
                        range(80, 88), range(96, 136), range(144, 152)):
            offset = ri << 2
            value = self.read(offset)
            print(
                f"{ri:4d} (offset:0x{offset:04x}): value = {value:10d} (0x{value:08x}) ({bin(value)})")

    def dump_debug_info(self, show_registers=False):
        """ Dump debug info. """

        def b(value, bit_index):
            return (value >> bit_index) & 1

        def bslice(value, bhi, bli):
            return (value >> bli) & ((1 << (bhi - bli + 1)) - 1)

        print("Debug Dump:")
        control_reg_value = self.ctrl_reg
        print(f"0x{self.CTRL_REG_ADDR:04x} (Control register):")
        print(f"   rst:{b(control_reg_value, 0)} gie:{b(control_reg_value, 1)}")
        status_reg_value = self.status_reg
        print(f"0x{self.STATUS_REG_ADDR:04x} (Status register):")
        print(
            f"   start:{b(status_reg_value, 0)} done:{b(status_reg_value, 1)}"
            f" idle:{b(status_reg_value, 2)} ready:{b(status_reg_value, 3)}"
        )

        iarg_rqt_en_reg_value = self.iarg_rqt_en_reg
        print(
            f"0x{self.IARG_RQT_EN_REG_ADDR:04x} (Input argument request enable register): 0x{iarg_rqt_en_reg_value:08x}")
        for i in range(8):
            if not b(iarg_rqt_en_reg_value, i): continue
            print(f"   iarg{i}_en = {b(iarg_rqt_en_reg_value, i)}")

        oarg_rqt_en_reg_value = self.oarg_rqt_en_reg
        print(
            f"0x{self.OARG_RQT_EN_REG_ADDR:04x} (Output argument request enable register): 0x{oarg_rqt_en_reg_value:08x}")
        for i in range(8):
            if not b(oarg_rqt_en_reg_value, i): continue
            print(f"   oarg{i}_en = {b(oarg_rqt_en_reg_value, i)}")

        oarg_length_mode_reg_value = self.oarg_length_mode_reg
        print(
            f"0x{self.OARG_LENGTH_MODE_REG_ADDR:04x} (Output argument length mode register): 0x{oarg_length_mode_reg_value:08x}")
        for i in range(8):
            if not b(oarg_rqt_en_reg_value, i): continue
            print(
                f"   oarg{i}_mode = {b(oarg_length_mode_reg_value, i)} ({self.OutputArgumentLengthModeEnum(b(oarg_length_mode_reg_value, i)).name})")

        print(f"0x{self.IARG_STATUS_REG_BASE_ADDR:04x} (Input buffer status register):")
        for i in range(8):
            if not b(iarg_rqt_en_reg_value, i): continue
            iarg_status_reg_value = self.get_iarg_status_reg(i)
            print(
                f"   iarg{i}_status = used_buf:{bslice(iarg_status_reg_value, 3, 0)}, empty:{b(iarg_status_reg_value, 4)}, full:{b(iarg_status_reg_value, 5)}")

        print(f"0x{self.OARG_STATUS_REG_BASE_ADDR:04x} (Output buffer status register):")
        for i in range(8):
            if not b(oarg_rqt_en_reg_value, i): continue
            oarg_status_reg_value = self.get_oarg_status_reg(i)
            print(
                f"   oarg{i}_status = used_buf:{bslice(oarg_status_reg_value, 3, 0)}, empty:{b(oarg_status_reg_value, 4)}, full:{b(oarg_status_reg_value, 5)}")

        print(
            f"0x{self.ISCALAR_STATUS_REG_BASE_ADDR:04x} (Input scalar status register):")
        for i in range(8):
            iscalar_status_reg_value = self.get_iscalar_status_reg(i)
            print(
                f"   iscalar{i}_status = used_buf:{bslice(iscalar_status_reg_value, 3, 0)}, empty:{b(iscalar_status_reg_value, 4)}, full:{b(iscalar_status_reg_value, 5)}")

        print(
            f"0x{self.OSCALAR_STATUS_REG_BASE_ADDR:04x} (Output scalar status register):")
        for i in range(8):
            oscalar_status_reg_value = self.get_oscalar_status_reg(i)
            print(
                f"   oscalar{i}_status = used_buf:{bslice(oscalar_status_reg_value, 3, 0)}, empty:{b(oscalar_status_reg_value, 4)}, full:{b(oscalar_status_reg_value, 5)}")

        print()
        if show_registers:
            self.dump_registers()
