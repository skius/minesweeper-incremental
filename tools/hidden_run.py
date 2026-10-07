"""Render Godot on an isolated Windows desktop, with an owned process handle.
No input injection, screen capture, focus changes, or process-name termination.
Godot itself supplies scripted input and viewport captures.
"""
import argparse
import ctypes as c
from ctypes import wintypes as w
import os
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--engine', required=True)
parser.add_argument('--project', required=True)
parser.add_argument('--log', required=True)
parser.add_argument('--timeout', type=int, default=180)
args = parser.parse_args()

class STARTUPINFO(c.Structure):
    _fields_ = [('cb',w.DWORD),('lpReserved',w.LPWSTR),('lpDesktop',w.LPWSTR),('lpTitle',w.LPWSTR),('dwX',w.DWORD),('dwY',w.DWORD),('dwXSize',w.DWORD),('dwYSize',w.DWORD),('dwXCountChars',w.DWORD),('dwYCountChars',w.DWORD),('dwFillAttribute',w.DWORD),('dwFlags',w.DWORD),('wShowWindow',w.WORD),('cbReserved2',w.WORD),('lpReserved2',c.POINTER(c.c_byte)),('hStdInput',w.HANDLE),('hStdOutput',w.HANDLE),('hStdError',w.HANDLE)]
class PROCESSINFO(c.Structure):
    _fields_ = [('hProcess',w.HANDLE),('hThread',w.HANDLE),('dwProcessId',w.DWORD),('dwThreadId',w.DWORD)]
user = c.WinDLL('user32', use_last_error=True)
kernel = c.WinDLL('kernel32', use_last_error=True)
user.CreateDesktopW.argtypes = [w.LPCWSTR,w.LPCWSTR,c.c_void_p,w.DWORD,w.DWORD,c.c_void_p]
user.CreateDesktopW.restype = w.HANDLE
user.CloseDesktop.argtypes = [w.HANDLE]
kernel.CreateProcessW.argtypes = [w.LPCWSTR,w.LPWSTR,c.c_void_p,c.c_void_p,w.BOOL,w.DWORD,c.c_void_p,w.LPCWSTR,c.POINTER(STARTUPINFO),c.POINTER(PROCESSINFO)]
kernel.WaitForSingleObject.argtypes = [w.HANDLE,w.DWORD]
kernel.GetExitCodeProcess.argtypes = [w.HANDLE,c.POINTER(w.DWORD)]
kernel.TerminateProcess.argtypes = [w.HANDLE,w.UINT]
kernel.CloseHandle.argtypes = [w.HANDLE]
desktop_name = 'AfterlightTest_' + str(os.getpid())
desktop = user.CreateDesktopW(desktop_name, None, None, 0, 0x10000000, None)
if not desktop:
    raise c.WinError(c.get_last_error())
si = STARTUPINFO()
si.cb = c.sizeof(si)
si.lpDesktop = desktop_name
pi = PROCESSINFO()
command = [args.engine,'--path',args.project,'--audio-driver','Dummy','--resolution','1440x900','--fixed-fps','60','--log-file',args.log,'--','--visual-test','--test-data='+os.path.join(args.project,'test_runs','visual_data')]
try:
    if not kernel.CreateProcessW(None, c.create_unicode_buffer(subprocess.list2cmdline(command)), None, None, False, 0x08000000, None, args.project, c.byref(si), c.byref(pi)):
        raise c.WinError(c.get_last_error())
    print('Native render session started on isolated desktop; PID', pi.dwProcessId, flush=True)
    wait = kernel.WaitForSingleObject(pi.hProcess, args.timeout * 1000)
    if wait == 258:
        kernel.TerminateProcess(pi.hProcess, 124)
        kernel.WaitForSingleObject(pi.hProcess, 5000)
        print('FAIL: native render timeout', flush=True)
        sys.exit(124)
    code = w.DWORD()
    kernel.GetExitCodeProcess(pi.hProcess, c.byref(code))
    sys.exit(code.value)
finally:
    if pi.hThread: kernel.CloseHandle(pi.hThread)
    if pi.hProcess: kernel.CloseHandle(pi.hProcess)
    user.CloseDesktop(desktop)
