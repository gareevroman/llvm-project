; RUN: opt %loadPolly -polly-opt-isl -polly-pattern-matching-based-opts=true \
; RUN: -analyze -polly-ast -polly-pattern-matching-based-tc-opts=true < %s \
; RUN: | FileCheck %s
; REQUIRES: asserts
;
;      for (i = 0; i < 32; i++)
;        for (j = 0; j < 1024; j++)
;          for (k = 0; k < 32; ++k)
;            for (l = 0; l < 1024; ++l)
;              C[i][j][k] += A[i][k][l] * B[l][j];
;
; CHECK:    // 1st level tiling - Tiles
; CHECK-NEXT:    for (int c1 = 0; c1 <= 2; c1 += 1) {
; CHECK-NEXT:      for (int c4 = 0; c4 <= 31; c4 += 1)
; CHECK-NEXT:        for (int c5 = 0; c5 <= 31; c5 += 1)
; CHECK-NEXT:          for (int c6 = 384 * c1; c6 <= min(1023, 384 * c1 + 383); c6 += 1)
; CHECK-NEXT:            CopyStmt_0(0, c1, c4, c5, c6);
; CHECK-NEXT:      for (int c2 = 0; c2 <= 15; c2 += 1) {
; CHECK-NEXT:        for (int c6 = 384 * c1; c6 <= min(1023, 384 * c1 + 383); c6 += 1)
; CHECK-NEXT:          for (int c7 = 64 * c2; c7 <= 64 * c2 + 63; c7 += 1)
; CHECK-NEXT:            CopyStmt_1(0, c1, c2, c6, c7);
; CHECK-NEXT:        // 1st level tiling - Points
; CHECK-NEXT:        // Register tiling - Tiles
; CHECK-NEXT:        for (int c3 = 0; c3 <= 255; c3 += 1)
; CHECK-NEXT:          for (int c4 = 0; c4 <= 15; c4 += 1)
; CHECK-NEXT:            for (int c5 = 0; c5 <= min(383, -384 * c1 + 1023); c5 += 1) {
; CHECK-NEXT:              // Loop Vectorizer Disabled
; CHECK-NEXT:              // Register tiling - Points
; CHECK-NEXT:              {
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4, 4 * (c3 % 8), 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4, 4 * (c3 % 8) + 1, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4, 4 * (c3 % 8) + 2, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4, 4 * (c3 % 8) + 3, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 1, 4 * (c3 % 8), 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 1, 4 * (c3 % 8) + 1, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 1, 4 * (c3 % 8) + 2, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 1, 4 * (c3 % 8) + 3, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 2, 4 * (c3 % 8), 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 2, 4 * (c3 % 8) + 1, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 2, 4 * (c3 % 8) + 2, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 2, 4 * (c3 % 8) + 3, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 3, 4 * (c3 % 8), 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 3, 4 * (c3 % 8) + 1, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 3, 4 * (c3 % 8) + 2, 384 * c1 + c5);
; CHECK-NEXT:                Stmt_for_body9(c3 / 8, 64 * c2 + 4 * c4 + 3, 4 * (c3 % 8) + 3, 384 * c1 + c5);
; CHECK-NEXT:              }
; CHECK-NEXT:            }
; CHECK-NEXT:      }
; CHECK-NEXT:    }
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define internal void @kernel_tc(i32 %ni, i32 %nj, i32 %nk, i32 %nl, double %alpha, double %beta, [1024 x [32 x double]]* %C, [32 x [1024 x double]]* %A, [1024 x double]* %B) {
entry:
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.inc30, %entry
  %indvars.iv43 = phi i64 [ 0, %entry ], [ %indvars.iv.next44, %for.inc30 ]
  br label %for.cond4.preheader

for.cond4.preheader:                              ; preds = %for.inc27, %for.cond1.preheader
  %indvars.iv40 = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next41, %for.inc27 ]
  br label %for.cond7.preheader

for.cond7.preheader:                              ; preds = %for.inc24, %for.cond4.preheader
  %indvars.iv37 = phi i64 [ 0, %for.cond4.preheader ], [ %indvars.iv.next38, %for.inc24 ]
  br label %for.body9

for.body9:                                        ; preds = %for.body9, %for.cond7.preheader
  %indvars.iv = phi i64 [ 0, %for.cond7.preheader ], [ %indvars.iv.next, %for.body9 ]
  %arrayidx13 = getelementptr inbounds [32 x [1024 x double]], [32 x [1024 x double]]* %A, i64 %indvars.iv43, i64 %indvars.iv37, i64 %indvars.iv
  %i = load double, double* %arrayidx13, align 8
  %arrayidx17 = getelementptr inbounds [1024 x double], [1024 x double]* %B, i64 %indvars.iv, i64 %indvars.iv40
  %i1 = load double, double* %arrayidx17, align 8
  %mul = fmul fast double %i1, %i
  %arrayidx23 = getelementptr inbounds [1024 x [32 x double]], [1024 x [32 x double]]* %C, i64 %indvars.iv43, i64 %indvars.iv40, i64 %indvars.iv37
  %i2 = load double, double* %arrayidx23, align 8
  %add = fadd fast double %i2, %mul
  store double %add, double* %arrayidx23, align 8
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, 1024
  br i1 %exitcond, label %for.body9, label %for.inc24

for.inc24:                                        ; preds = %for.body9
  %indvars.iv.next38 = add nuw nsw i64 %indvars.iv37, 1
  %exitcond39 = icmp ne i64 %indvars.iv.next38, 32
  br i1 %exitcond39, label %for.cond7.preheader, label %for.inc27

for.inc27:                                        ; preds = %for.inc24
  %indvars.iv.next41 = add nuw nsw i64 %indvars.iv40, 1
  %exitcond42 = icmp ne i64 %indvars.iv.next41, 1024
  br i1 %exitcond42, label %for.cond4.preheader, label %for.inc30

for.inc30:                                        ; preds = %for.inc27
  %indvars.iv.next44 = add nuw nsw i64 %indvars.iv43, 1
  %exitcond45 = icmp ne i64 %indvars.iv.next44, 32
  br i1 %exitcond45, label %for.cond1.preheader, label %for.end32

for.end32:                                        ; preds = %for.inc30
  ret void
}
