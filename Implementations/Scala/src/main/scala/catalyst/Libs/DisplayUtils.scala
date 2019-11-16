package catalyst.libs

import catalyst.model.{CatalystObjectSchedule, _}

object DisplayUtils {
  def contentToString(c: CatalystObjectContents): Array[String] = {
    Array(
      c.line
    )
  }
  def waveScheduleToString(waveSchedule: WaveSchedule): String = {
    waveSchedule.toString
  }
  def scheduleToString(s: CatalystObjectSchedule): Array[String] = {
    s match {
      case CatalystObjectScheduleWaveItem(metric, waveSchedule) => Array(metric.toString, waveScheduleToString(waveSchedule))
      case x: Any => Array(x.toString)
    }
  }
  def catalystObjectToString(o: CatalystObject): String = {
    Array(
      "[  2]",
      " ",
      "(0.840)",
      " ",
      scheduleToString(o.schedule).mkString,
      contentToString(o.content).mkString
    ).mkString
  }
}