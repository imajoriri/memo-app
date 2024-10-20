enum PullToMode {
  /// 初期状態
  inactive,

  /// 初期状態から最初の閾値までの間
  drag,

  /// 閾値を超えた
  overFirstThreshold,

  /// 閾値を超えた
  overSecondThreshold,

  doing,
  done,
}
