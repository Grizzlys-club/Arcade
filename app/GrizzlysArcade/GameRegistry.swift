import SpriteKit

enum GameRegistry {
    static func type(_ k: GameKind) -> MiniScene.Type {
        switch k {
        case .penalty: return PenaltyGame.self
        case .goalie: return GoalieGame.self
        case .airhockey: return AirHockeyGame.self
        case .puckgolf: return PuckGolfGame.self
        case .ballrain: return BallRainGame.self
        case .powershot: return PowerShotGame.self
        case .hotpuck: return HotPuckGame.self
        case .sumo: return SumoGame.self
        case .ninja: return NinjaGame.self
        case .juggle: return JuggleGame.self
        case .quiz: return QuizGame.self
        case .duel: return DuelGame.self
        case .dash: return DashGame.self
        case .flappy: return FlappyGame.self
        case .hopper: return HopperGame.self
        case .stack: return StackGame.self
        case .simon: return SimonGame.self
        case .reaction: return ReactionGame.self
        case .numbers: return NumbersGame.self
        case .colors: return ColorsGame.self
        case .balance: return BalanceGame.self
        case .territory: return TerritoryGame.self
        case .tapsprint: return TapSprintGame.self
        case .whack: return WhackGame.self
        case .memory: return MemoryGame.self
        case .curling: return CurlingGame.self
        case .slalom: return SlalomGame.self
        case .pong: return PongGame.self
        case .bowling: return BowlingGame.self
        case .tugwar: return TugWarGame.self
        case .darts: return DartsGame.self
        case .hoops: return HoopsGame.self
        case .hurdles: return HurdlesGame.self
        case .mathduel: return MathDuelGame.self
        case .rhythm: return RhythmGame.self
        case .billiard: return BilliardGame.self
        case .arrows: return ArrowsGame.self
        case .oddone: return OddOneGame.self
        case .compare: return CompareGame.self
        case .sorter: return SorterGame.self
        case .dodge: return DodgeGame.self
        case .cave: return CaveGame.self
        case .pendulum: return PendulumGame.self
        case .count: return CountGame.self
        case .stoptime: return StopTimeGame.self
        case .slide: return SlideGame.self
        case .snowball: return SnowballGame.self
        case .zigzag: return ZigzagGame.self
        case .lightsout: return LightsOutGame.self
        case .reflex: return ReflexGame.self
        }
    }

    static func make(_ k: GameKind) -> MiniScene {
        return type(k).init(size: CGSize(width: SW, height: SH))
    }

    static func layout(_ k: GameKind) -> SeatLayout {
        return type(k).layout
    }
}
