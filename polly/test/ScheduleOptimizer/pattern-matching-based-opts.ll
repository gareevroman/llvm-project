; RUN: opt %loadPolly -polly-opt-isl -polly-pattern-matching-based-opts=false \
; RUN: -debug -polly-pattern-matching-based-tc-opts < %s 2>&1| FileCheck %s
; RUN: opt %loadPolly -polly-opt-isl -polly-pattern-matching-based-opts=true -debug < %s 2>&1| FileCheck %s --check-prefix=PATTERN-MATCHING-OPTS
; RUN: opt %loadPolly -polly-opt-isl -polly-pattern-matching-based-opts=true -polly-ast-detect-parallel -polly-ast -analyze < %s | FileCheck %s --check-prefix=PARALLEL-AST
; RUN: opt %loadPolly -polly-opt-isl -polly-pattern-matching-based-opts=true -stats -disable-output < %s 2>&1| FileCheck %s --check-prefix=STATS -match-full-lines
; REQUIRES: asserts
;
;    /* C := alpha*A*B + beta*C */
;    for (i = 0; i < _PB_NI; i++)
;      for (j = 0; j < _PB_NJ; j++)
;        {
;	   C[i][j] *= beta;
;	   for (k = 0; k < _PB_NK; ++k)
;	     C[i][j] += alpha * A[i][k] * B[k][j];
;        }
;
; CHECK-NOT: The matrix multiplication pattern was detected
; CHECK-NOT: The tensor contraction pattern was detected
; PATTERN-MATCHING-OPTS: The matrix multiplication pattern was detected
; PARALLEL-AST: #pragma known-parallel
; PARALLEL-AST: #pragma known-parallel
; STATS:  1 polly-opt-isl    - Number of matrix multiplication patterns detected and optimized
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-unknown"

define internal void @kernel_gemm(i32 %arg, i32 %arg1, i32 %arg2, double %arg3, double %arg4, [1056 x double]* %arg5, [1024 x double]* %arg6, [1056 x double]* %arg7) #0 {
bb:
  br label %bb8

bb8:                                              ; preds = %bb29, %bb
  %tmp = phi i64 [ 0, %bb ], [ %tmp30, %bb29 ]
  br label %bb9

bb9:                                              ; preds = %bb26, %bb8
  %tmp10 = phi i64 [ 0, %bb8 ], [ %tmp27, %bb26 ]
  %tmp11 = getelementptr inbounds [1056 x double], [1056 x double]* %arg5, i64 %tmp, i64 %tmp10
  %tmp12 = load double, double* %tmp11, align 8
  %tmp13 = fmul double %tmp12, %arg4
  store double %tmp13, double* %tmp11, align 8
  br label %Copy_0

Copy_0:                                             ; preds = %Copy_0, %bb9
  %tmp15 = phi i64 [ 0, %bb9 ], [ %tmp24, %Copy_0 ]
  %tmp16 = getelementptr inbounds [1024 x double], [1024 x double]* %arg6, i64 %tmp, i64 %tmp15
  %tmp17 = load double, double* %tmp16, align 8
  %tmp18 = fmul double %tmp17, %arg3
  %tmp19 = getelementptr inbounds [1056 x double], [1056 x double]* %arg7, i64 %tmp15, i64 %tmp10
  %tmp20 = load double, double* %tmp19, align 8
  %tmp21 = fmul double %tmp18, %tmp20
  %tmp22 = load double, double* %tmp11, align 8
  %tmp23 = fadd double %tmp22, %tmp21
  store double %tmp23, double* %tmp11, align 8
  %tmp24 = add nuw nsw i64 %tmp15, 1
  %tmp25 = icmp ne i64 %tmp24, 1024
  br i1 %tmp25, label %Copy_0, label %bb26

bb26:                                             ; preds = %Copy_0
  %tmp27 = add nuw nsw i64 %tmp10, 1
  %tmp28 = icmp ne i64 %tmp27, 1056
  br i1 %tmp28, label %bb9, label %bb29

bb29:                                             ; preds = %bb26
  %tmp30 = add nuw nsw i64 %tmp, 1
  %tmp31 = icmp ne i64 %tmp30, 1056
  br i1 %tmp31, label %bb8, label %bb32

bb32:                                             ; preds = %bb29
  ret void
}
