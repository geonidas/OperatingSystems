import re
from gradelib import *

r = Runner(save("xv6.out"))

@test(25, "trace 32 grep")
def test_trace_32_grep():
    r.run_qemu(shell_script([
        'trace 32 grep hello README'
    ]))
    r.match('^\\d+: syscall read -> 1023')
    r.match('^\\d+: syscall read -> 966')
    r.match('^\\d+: syscall read -> 0')

@test(25, "trace all grep")
def test_trace_all_grep():
    r.run_qemu(shell_script([
        'trace 2147483647 grep hello README'
    ]))
    r.match('^\\d+: syscall trace -> 0')
    r.match('^\\d+: syscall exec -> 3')
    r.match('^\\d+: syscall open -> 3')
    r.match('^\\d+: syscall read -> 1023')
    r.match('^\\d+: syscall read -> 966')
    r.match('^\\d+: syscall read -> 0')
    r.match('^\\d+: syscall close -> 0')

@test(25, "trace nothing")
def test_trace_nothing():
    r.run_qemu(shell_script([
        'grep hello README'
    ]))
    r.match(no=[".* syscall .*"])


@test(75, "sysinfotest")
def test_sysinfotest():
    r.run_qemu(shell_script([
        'sysinfotest'
    ]))
    r.match('^sysinfotest: OK', no=[".* FAIL .*"])

@test(50, "time cat README")
def test_time_32():
    r.run_qemu(shell_script([
        'time cat README'
    ]))
    r.match('^Real-time in ticks: \\d+')

run_tests()
