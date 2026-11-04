define i32 @test_sub(i32 %x) {
entry:
  %a = sub i32 %x, 0
  %b = add i32 %a, 0
  ret i32 %b
}

define i32 @test_keep_sub(i32 %x) {
entry:
  %a = sub i32 0, %x
  ret i32 %a
}
