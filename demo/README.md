## Environment

If you want to use ROSbot 2R replace [the launchfile](https://github.com/husarion/webots-docker/blob/main/demo/compose.yaml#L35) with `rosbot_launch.py`.

## Run with `docker compose`

Select the ROSbot:
```bash
export ROBOT_NAME=rosbot # or rosbot_xl
```

To start simulation build and run webots simulator container type:

```bash
docker compose up
```

It will take a while because the container has to download required assets.

Wait until this messages show up in the Webots console.

> INFO: 'rosbot' extern controller: connected.
>
> INFO: 'Ros2Supervisor' extern controller: connected.

For visualization the ROSbots sensors run RViz2 in the another terminal:

```bash
docker compose -f compose.rviz.yaml up
```

Now you can use `teleop_twist` tool to drive ROSbot with keyboard.
Enter `rviz` container in the new terminal:

```bash
docker exec -it rviz bash
```

Now, to teleoperate the ROSbot with your keyboard, execute:

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

# ROSbot webots mapping demo

Try webots mapping demo [here](https://github.com/husarion/rosbot-mapping#quick-start-webots-simulation).
