define i32 @test_mul(i32 %x) {
entry:
  %a = mul i32 %x, 1
  %b = mul i32 1, %a
  %c = add i32 %b, 0
  ret i32 %c
}
