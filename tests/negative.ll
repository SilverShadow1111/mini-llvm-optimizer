define i32 @test_negative(i32 %x) {
entry:
  %a = add i32 %x, 5
  %b = mul i32 %a, 2
  ret i32 %b
}
