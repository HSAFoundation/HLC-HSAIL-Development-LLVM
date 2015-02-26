; XFAIL: *
; RUN: llc -march=hsail < %s

define void @has-hypens-in-name() {
 ret void
}
