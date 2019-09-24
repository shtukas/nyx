package catalyst

case class CatalystObject(
  uuid: String,
  agentuid: String,
  content: CatalystObjectContents,
  schedule: CatalystObjectSchedule,
  isDone: Boolean,
)

case class CatalystObjectContents(line: String, body: Option[String])

trait CatalystObjectSchedule {}

case class CatalystObjectScheduleTodoAndInformAgent(metric: Float) extends CatalystObjectSchedule
case class CatalystObjectScheduleToActiveAndInformAgent(metric: Float) extends CatalystObjectSchedule
