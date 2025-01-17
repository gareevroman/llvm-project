; RUN: opt %loadPolly -polly-opt-isl -polly-pattern-matching-based-opts=true \
; RUN: -analyze -polly-ast -polly-pattern-matching-based-tc-opts=true < %s \
; RUN: | FileCheck %s
; REQUIRES: asserts
;
;   for (i = 0; i < 8; i++)
;     for (j = 0; j < 8; j++)
;       for (k = 0; k < 4; ++k)
;         for (l = 0; l < 1024; ++l)
;           for (w = 0; w < 1024; ++w)
;             for (q = 0; q < 4; ++q)
;               C[i][j][k][w][q] += A[q][k][j][l][i] * B[l][w];
;
; CHECK:    // 1st level tiling - Tiles
; CHECK-NEXT:    for (int c1 = 0; c1 <= 2; c1 += 1) {
; CHECK-NEXT:      for (int c4 = 0; c4 <= 3; c4 += 1)
; CHECK-NEXT:        for (int c5 = 0; c5 <= 3; c5 += 1)
; CHECK-NEXT:          for (int c6 = 0; c6 <= 7; c6 += 1)
; CHECK-NEXT:            for (int c7 = 384 * c1; c7 <= min(1023, 384 * c1 + 383); c7 += 1)
; CHECK-NEXT:              for (int c8 = 0; c8 <= 7; c8 += 1)
; CHECK-NEXT:                CopyStmt_0(0, c1, c4, c5, c6, c7, c8);
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
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4, 0);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4, 1);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4, 2);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4, 3);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 1, 0);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 1, 1);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 1, 2);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 1, 3);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 2, 0);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 2, 1);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 2, 2);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 2, 3);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 3, 0);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 3, 1);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 3, 2);
; CHECK-NEXT:                Stmt_for_body15(c3 - (31 * c3 + 31) / 32, -7 * c3 - (3 * c3 + 3) / 4 + 8 * ((31 * c3 + 31) / 32), c3 % 4, 384 * c1 + c5, 64 * c2 + 4 * c4 + 3, 3);
; CHECK-NEXT:              }
; CHECK-NEXT:            }
; CHECK-NEXT:      }
; CHECK-NEXT:    }
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define internal void @kernel_tc([8 x [4 x [1024 x [4 x double]]]]* %C, [4 x [8 x [1024 x [8 x double]]]]* %A, [1024 x double]* %B) {
entry:
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.inc50, %entry
  %indvars.iv71 = phi i64 [ 0, %entry ], [ %indvars.iv.next72, %for.inc50 ]
  br label %for.cond4.preheader

for.cond4.preheader:                              ; preds = %for.inc47, %for.cond1.preheader
  %indvars.iv68 = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next69, %for.inc47 ]
  br label %for.cond7.preheader

for.cond7.preheader:                              ; preds = %for.inc44, %for.cond4.preheader
  %indvars.iv65 = phi i64 [ 0, %for.cond4.preheader ], [ %indvars.iv.next66, %for.inc44 ]
  br label %for.cond10.preheader

for.cond10.preheader:                             ; preds = %for.inc41, %for.cond7.preheader
  %indvars.iv62 = phi i64 [ 0, %for.cond7.preheader ], [ %indvars.iv.next63, %for.inc41 ]
  br label %for.cond13.preheader

for.cond13.preheader:                             ; preds = %for.inc38, %for.cond10.preheader
  %indvars.iv59 = phi i64 [ 0, %for.cond10.preheader ], [ %indvars.iv.next60, %for.inc38 ]
  br label %for.body15

for.body15:                                       ; preds = %for.body15, %for.cond13.preheader
  %indvars.iv = phi i64 [ 0, %for.cond13.preheader ], [ %indvars.iv.next, %for.body15 ]
  %arrayidx23 = getelementptr inbounds [4 x [8 x [1024 x [8 x double]]]], [4 x [8 x [1024 x [8 x double]]]]* %A, i64 %indvars.iv, i64 %indvars.iv65, i64 %indvars.iv68, i64 %indvars.iv62, i64 %indvars.iv71
  %i = load double, double* %arrayidx23, align 8
  %arrayidx27 = getelementptr inbounds [1024 x double], [1024 x double]* %B, i64 %indvars.iv62, i64 %indvars.iv59
  %i1 = load double, double* %arrayidx27, align 8
  %mul = fmul fast double %i1, %i
  %arrayidx37 = getelementptr inbounds [8 x [4 x [1024 x [4 x double]]]], [8 x [4 x [1024 x [4 x double]]]]* %C, i64 %indvars.iv71, i64 %indvars.iv68, i64 %indvars.iv65, i64 %indvars.iv59, i64 %indvars.iv
  %i2 = load double, double* %arrayidx37, align 8
  %add = fadd fast double %i2, %mul
  store double %add, double* %arrayidx37, align 8
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, 4
  br i1 %exitcond, label %for.body15, label %for.inc38

for.inc38:                                        ; preds = %for.body15
  %indvars.iv.next60 = add nuw nsw i64 %indvars.iv59, 1
  %exitcond61 = icmp ne i64 %indvars.iv.next60, 1024
  br i1 %exitcond61, label %for.cond13.preheader, label %for.inc41

for.inc41:                                        ; preds = %for.inc38
  %indvars.iv.next63 = add nuw nsw i64 %indvars.iv62, 1
  %exitcond64 = icmp ne i64 %indvars.iv.next63, 1024
  br i1 %exitcond64, label %for.cond10.preheader, label %for.inc44

for.inc44:                                        ; preds = %for.inc41
  %indvars.iv.next66 = add nuw nsw i64 %indvars.iv65, 1
  %exitcond67 = icmp ne i64 %indvars.iv.next66, 4
  br i1 %exitcond67, label %for.cond7.preheader, label %for.inc47

for.inc47:                                        ; preds = %for.inc44
  %indvars.iv.next69 = add nuw nsw i64 %indvars.iv68, 1
  %exitcond70 = icmp ne i64 %indvars.iv.next69, 8
  br i1 %exitcond70, label %for.cond4.preheader, label %for.inc50

for.inc50:                                        ; preds = %for.inc47
  %indvars.iv.next72 = add nuw nsw i64 %indvars.iv71, 1
  %exitcond73 = icmp ne i64 %indvars.iv.next72, 8
  br i1 %exitcond73, label %for.cond1.preheader, label %for.end52

for.end52:                                        ; preds = %for.inc50
  ret void
}
