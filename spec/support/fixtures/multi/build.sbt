lazy val root = (project in file(".")).
  settings(
    name := "hello",
    version := "1.0",
    scalaVersion := "2.11.7"
  )

lazy val one = (project in file("one")).
  settings(
    name := "1"
  )

lazy val two = (project in file("two")).
  settings(
    name := "2"
  ).dependsOn(one)
