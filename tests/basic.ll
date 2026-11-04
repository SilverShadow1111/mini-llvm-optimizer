define i32 @test(i32 %x) {
entry:
  %a = add i32 %x, 0
  %b = add i32 0, %a
  ret i32 %b
}
