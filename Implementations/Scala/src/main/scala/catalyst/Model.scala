package catalyst.model

case class CatalystObject(
  uuid: String,
  agentuid: String,
  content: CatalystObjectContents,
  schedule: CatalystObjectSchedule,
  isDone: Boolean,
)

case class CatalystObjectContents(line: String, body: Option[String] = None)

sealed trait WaveSchedule
case class WaveScheduleSticky(fromHour: Int)
case class WaveScheduleRepeatEveryNHours(value: Float)
case class WaveScheduleRepeatEveryNDays(value: Float)
case class WaveScheduleThisDayOfTheWeek(value: String)
case class WaveScheduleThisDayOfTheMonth(value: String)

sealed trait CatalystObjectSchedule
case class CatalystObjectScheduleTodoAndInformAgent(metric: Float) extends CatalystObjectSchedule
case class CatalystObjectScheduleToActiveAndInformAgent(metric: Float) extends CatalystObjectSchedule
case class CatalystObjectSchedule24HoursSlidingTimeCommitment
(
  collectionuid: String,
  commitmentInHours : Float,
  stabilityPeriodInSeconds: Float,
  metricAtZero: Float,
  metricAtTarget: Float
) extends CatalystObjectSchedule
case class CatalystObjectScheduleStreamItem
(
  collectionuid: String,
  ordinal: Float,
  commitmentInHours : Float,
  stabilityPeriodInSeconds: Float,
  metricAtZero: Float,
  metricAtTarget: Float
) extends CatalystObjectSchedule
case class CatalystObjectScheduleWaveItem
(
  metric: Float,
  waveSchedule: WaveSchedule
) extends CatalystObjectSchedule
