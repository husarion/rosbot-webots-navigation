## Environment

In the [.env](.env) file you can choose a robot and a dds configuration you want to work with.

## Run with `docker compose`

To start simulation build and run webots simulator container type:

```bash
docker compose up
```

It will take a while because the container has to download required assets.

Wait until this messages show up in the Webots console.

> INFO: 'rosbot' extern controller: connected.
>
> INFO: 'Ros2Supervisor' extern controller: connected.

Now you can use `teleop_twist` tool to drive ROSbot with keyboard.

Enter `rviz` container:

```bash
docker exec -it rviz bash
```

Now, to teleoperate the ROSbot with your keyboard, execute:

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

# ROSbot webots mapping demo

Try webots mapping demo [here](https://github.com/husarion/rosbot-mapping#quick-start-webots-simulation).