class DebateRound {
  final String label;
  final int durationSeconds;

  const DebateRound({required this.label, required this.durationSeconds});
}

// Lincoln-Douglas Debate
const List<DebateRound> lincolnDouglasRounds = [
  DebateRound(label: "Affirmative Constructive", durationSeconds: 360),
  DebateRound(label: "Negative Cross-Examination", durationSeconds: 180),
  DebateRound(label: "Negative Constructive", durationSeconds: 420),
  DebateRound(label: "Affirmative Cross-Examination", durationSeconds: 180),
  DebateRound(label: "Affirmative Rebuttal", durationSeconds: 240),
  DebateRound(label: "Negative Rebuttal", durationSeconds: 360),
  DebateRound(label: "Affirmative Closing", durationSeconds: 180),
];

// Policy Debate
const List<DebateRound> policyRounds = [
  DebateRound(label: "1AC", durationSeconds: 480),
  DebateRound(label: "CX by Neg", durationSeconds: 180),
  DebateRound(label: "1NC", durationSeconds: 480),
  DebateRound(label: "CX by Aff", durationSeconds: 180),
  DebateRound(label: "2AC", durationSeconds: 480),
  DebateRound(label: "CX by Neg", durationSeconds: 180),
  DebateRound(label: "2NC", durationSeconds: 480),
  DebateRound(label: "CX by Aff", durationSeconds: 180),
  DebateRound(label: "1NR", durationSeconds: 300),
  DebateRound(label: "1AR", durationSeconds: 300),
  DebateRound(label: "2NR", durationSeconds: 300),
  DebateRound(label: "2AR", durationSeconds: 300),
];

// Public Forum Debate
const List<DebateRound> publicForumRounds = [
  DebateRound(label: "Team A Constructive", durationSeconds: 240),
  DebateRound(label: "Team B Constructive", durationSeconds: 240),
  DebateRound(label: "Crossfire", durationSeconds: 180),
  DebateRound(label: "Team A Rebuttal", durationSeconds: 240),
  DebateRound(label: "Team B Rebuttal", durationSeconds: 240),
  DebateRound(label: "Crossfire", durationSeconds: 180),
  DebateRound(label: "Team A Summary", durationSeconds: 120),
  DebateRound(label: "Team B Summary", durationSeconds: 120),
  DebateRound(label: "Final Focus A", durationSeconds: 120),
  DebateRound(label: "Final Focus B", durationSeconds: 120),
];

// Casual Mode
const List<DebateRound> casualRounds = [
  DebateRound(label: "Speaker 1 - Opening", durationSeconds: 120),
  DebateRound(label: "Speaker 2 - Opening", durationSeconds: 120),
  DebateRound(label: "Back and Forth", durationSeconds: 180),
  DebateRound(label: "Closing Arguments", durationSeconds: 90),
];
