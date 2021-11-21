; RUN: opt %loadPolly -polly-delicm -polly-simplify -polly-opt-isl \
; RUN: -polly-pattern-matching-based-opts=true \
; RUN: -polly-pattern-matching-based-tc-opts=true -analyze -polly-ast < %s \
; RUN: | FileCheck %s
; REQUIRES: asserts
;
; Check that the pattern matching detects the tensor contraction pattern
; after a full run of -polly-delicm. This test case generates the following
; schedule, which contans two band nodes. Without DeLICM two statement are
; generated.
;
; domain: "{ Stmt5[i0, i1, i2, i3, i4, i5] : 0 <= i0 <= 31 and 0 <= i1 <= 31 and
;                                            0 <= i2 <= 31 and 0 <= i3 <= 31 and
;                                            0 <= i4 <= 31 and 0 <= i5 <= 31 }"
; child:
;   schedule: "[{ Stmt5[i0, i1, i2, i3, i4, i5] -> [(i0)] },
;               { Stmt5[i0, i1, i2, i3, i4, i5] -> [(i1)] },
;               { Stmt5[i0, i1, i2, i3, i4, i5] -> [(i2)] },
;               { Stmt5[i0, i1, i2, i3, i4, i5] -> [(i4)] },
;               { Stmt5[i0, i1, i2, i3, i4, i5] -> [(i3)] }]"
;   permutable: 1
;   coincident: [ 1, 1, 1, 1, 0 ]
;   child:
;     schedule: "[{ Stmt5[i0, i1, i2, i3, i4, i5] -> [(i5)] }]"
;     permutable: 1
;     child:
;       leaf
;
;   for (i = 0; i < 32; i++)
;     for (j = 0; j < 32; j++)
;       for (k = 0; k < 32; ++k)
;         for (l = 0; l < 32; ++l)
;           for (w = 0; w < 32; ++w)
;             for (q = 0; q < 32; ++q)
;               C[i][j][k][w] += A[i][l][j][q] * B[q][w][l][k];
;
; CHECK:    // 1st level tiling - Tiles
; CHECK-NEXT:    for (int c1 = 0; c1 <= 2; c1 += 1) {
; CHECK-NEXT:      for (int c4 = 0; c4 <= 31; c4 += 1)
; CHECK-NEXT:        for (int c5 = 0; c5 <= 31; c5 += 1)
; CHECK-NEXT:          for (int c6 = 12 * c1; c6 <= min(31, 12 * c1 + 11); c6 += 1)
; CHECK-NEXT:            for (int c7 = 0; c7 <= 31; c7 += 1)
; CHECK-NEXT:              CopyStmt_0(0, c1, c4, c5, c6, c7);
; CHECK-NEXT:      for (int c2 = 0; c2 <= 15; c2 += 1) {
; CHECK-NEXT:        for (int c6 = 2 * c2; c6 <= 2 * c2 + 1; c6 += 1)
; CHECK-NEXT:          for (int c7 = 12 * c1; c7 <= min(31, 12 * c1 + 11); c7 += 1)
; CHECK-NEXT:            for (int c8 = 0; c8 <= 31; c8 += 1)
; CHECK-NEXT:              for (int c9 = 0; c9 <= 31; c9 += 1)
; CHECK-NEXT:                CopyStmt_1(0, c1, c2, c6, c7, c8, c9);
; CHECK-NEXT:        // 1st level tiling - Points
; CHECK-NEXT:        // Register tiling - Tiles
; CHECK-NEXT:        for (int c3 = 0; c3 <= 255; c3 += 1)
; CHECK-NEXT:          for (int c4 = 0; c4 <= 15; c4 += 1)
; CHECK-NEXT:            for (int c5 = 0; c5 <= min(383, -384 * c1 + 1023); c5 += 1) {
; CHECK-NEXT:              // Loop Vectorizer Disabled
; CHECK-NEXT:              // Register tiling - Points
; CHECK-NEXT:              {
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8), c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8), c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8), c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 1, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8), c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 2, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8), c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 3, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 1, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8), c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 1, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 1, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 1, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 2, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 1, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 3, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 2, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8), c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 2, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 1, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 2, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 2, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 2, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 3, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 3, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8), c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 3, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 1, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 3, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 2, c5 % 32);
; CHECK-NEXT:                Stmt_for_body15(2 * c2 + c4 / 8, 4 * (c4 % 8) + 3, c3 / 8, 12 * c1 + c5 / 32, 4 * (c3 % 8) + 3, c5 % 32);
; CHECK-NEXT:              }
; CHECK-NEXT:            }
; CHECK-NEXT:      }
; CHECK-NEXT:    }
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define internal fastcc void @kernel_tc([32 x [32 x [32 x double]]]* nocapture %C, [32 x [32 x [32 x double]]]* nocapture readonly %A, [32 x [32 x [32 x double]]]* nocapture readonly %B) {
entry:
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.inc50, %entry
  %indvars.iv19 = phi i64 [ 0, %entry ], [ %indvars.iv.next20, %for.inc50 ]
  br label %for.cond4.preheader

for.cond4.preheader:                              ; preds = %for.inc47, %for.cond1.preheader
  %indvars.iv16 = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next17, %for.inc47 ]
  br label %for.cond7.preheader

for.cond7.preheader:                              ; preds = %for.inc44, %for.cond4.preheader
  %indvars.iv13 = phi i64 [ 0, %for.cond4.preheader ], [ %indvars.iv.next14, %for.inc44 ]
  br label %for.cond10.preheader

for.cond10.preheader:                             ; preds = %for.inc41, %for.cond7.preheader
  %indvars.iv10 = phi i64 [ 0, %for.cond7.preheader ], [ %indvars.iv.next11, %for.inc41 ]
  br label %for.cond13.preheader

for.cond13.preheader:                             ; preds = %for.inc38, %for.cond10.preheader
  %indvars.iv7 = phi i64 [ 0, %for.cond10.preheader ], [ %indvars.iv.next8, %for.inc38 ]
  %arrayidx37 = getelementptr inbounds [32 x [32 x [32 x double]]], [32 x [32 x [32 x double]]]* %C, i64 %indvars.iv19, i64 %indvars.iv16, i64 %indvars.iv13, i64 %indvars.iv7
  %.pre = load double, double* %arrayidx37, align 8
  br label %for.body15

for.body15:                                       ; preds = %for.body15, %for.cond13.preheader
  %i = phi double [ %.pre, %for.cond13.preheader ], [ %add, %for.body15 ]
  %indvars.iv = phi i64 [ 0, %for.cond13.preheader ], [ %indvars.iv.next, %for.body15 ]
  %arrayidx21 = getelementptr inbounds [32 x [32 x [32 x double]]], [32 x [32 x [32 x double]]]* %A, i64 %indvars.iv19, i64 %indvars.iv10, i64 %indvars.iv16, i64 %indvars.iv
  %i1 = load double, double* %arrayidx21, align 8
  %arrayidx29 = getelementptr inbounds [32 x [32 x [32 x double]]], [32 x [32 x [32 x double]]]* %B, i64 %indvars.iv, i64 %indvars.iv7, i64 %indvars.iv10, i64 %indvars.iv13
  %i2 = load double, double* %arrayidx29, align 8
  %mul = fmul fast double %i2, %i1
  %add = fadd fast double %i, %mul
  store double %add, double* %arrayidx37, align 8
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, 32
  br i1 %exitcond.not, label %for.inc38, label %for.body15

for.inc38:                                        ; preds = %for.body15
  %indvars.iv.next8 = add nuw nsw i64 %indvars.iv7, 1
  %exitcond9.not = icmp eq i64 %indvars.iv.next8, 32
  br i1 %exitcond9.not, label %for.inc41, label %for.cond13.preheader

for.inc41:                                        ; preds = %for.inc38
  %indvars.iv.next11 = add nuw nsw i64 %indvars.iv10, 1
  %exitcond12.not = icmp eq i64 %indvars.iv.next11, 32
  br i1 %exitcond12.not, label %for.inc44, label %for.cond10.preheader

for.inc44:                                        ; preds = %for.inc41
  %indvars.iv.next14 = add nuw nsw i64 %indvars.iv13, 1
  %exitcond15.not = icmp eq i64 %indvars.iv.next14, 32
  br i1 %exitcond15.not, label %for.inc47, label %for.cond7.preheader

for.inc47:                                        ; preds = %for.inc44
  %indvars.iv.next17 = add nuw nsw i64 %indvars.iv16, 1
  %exitcond18.not = icmp eq i64 %indvars.iv.next17, 32
  br i1 %exitcond18.not, label %for.inc50, label %for.cond4.preheader

for.inc50:                                        ; preds = %for.inc47
  %indvars.iv.next20 = add nuw nsw i64 %indvars.iv19, 1
  %exitcond21.not = icmp eq i64 %indvars.iv.next20, 32
  br i1 %exitcond21.not, label %for.end52, label %for.cond1.preheader

for.end52:                                        ; preds = %for.inc50
  ret void
}
