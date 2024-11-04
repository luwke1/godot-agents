from gymnasium.envs.box2d import CarRacing
from gymnasium.envs.box2d.car_racing import FrictionDetector
from gymnasium.envs.registration import register
import gymnasium as gym
import numpy as np
from gymnasium.envs.box2d.car_dynamics import Car
from typing import Optional, Union
import pygame

STATE_W = 96
STATE_H = 96


# a custom environment that inherits from the carRacing environment
# changes colors from original environment to make it space themed
class customCarRacing(CarRacing):
    def __init__(
            self,
            render_mode: Optional[str] = None,
            verbose: bool = False,
            lap_complete_percent: float = 0.95,
            domain_randomize: bool = False,
            continuous: bool = True,
    ):
        super().__init__(render_mode, verbose, lap_complete_percent, domain_randomize, continuous)
        self.car: Optional[Rocket] = None

    def reset(
            self,
            *,
            seed: Optional[int] = None,
            options: Optional[dict] = None,
    ):
        super().reset(seed=seed)
        self._destroy()
        self.world.contactListener_bug_workaround = FrictionDetector(
            self, self.lap_complete_percent
        )
        self.world.contactListener = self.world.contactListener_bug_workaround
        self.reward = 0.0
        self.prev_reward = 0.0
        self.tile_visited_count = 0
        self.t = 0.0
        self.new_lap = False
        self.road_poly = []

        if self.domain_randomize:
            randomize = True
            if isinstance(options, dict):
                if "randomize" in options:
                    randomize = options["randomize"]

            self._reinit_colors(randomize)

        while True:
            success = self._create_track()
            if success:
                break
            if self.verbose:
                print(
                    "retry to generate track (normal if there are not many"
                    "instances of this message)"
                )
        self.car = Rocket(self.world, *self.track[0][1:4])

        if self.render_mode == "human":
            self.render()
        return self.step(None)[0], {}

    def _init_colors(self):
        if self.domain_randomize:
            # domain randomize the bg and grass colour
            self.road_color = self.np_random.uniform(0, 210, size=3)

            self.bg_color = self.np_random.uniform(0, 210, size=3)

            self.grass_color = np.copy(self.bg_color)
            idx = self.np_random.integers(3)
            self.grass_color[idx] += 20
        else:
            # default colours
            self.road_color = np.array([0, 0, 102])
            self.bg_color = np.array([0, 0, 0])
            self.grass_color = np.array([0, 0, 0])

    def _render_indicators(self, W, H):
        s = W / 40.0
        h = H / 40.0
        color = (0, 0, 0)
        polygon = [(W, H), (W, H - 5 * h), (0, H - 5 * h), (0, H)]
        pygame.draw.polygon(self.surf, color=color, points=polygon)

        def vertical_ind(place, val):
            return [
                (place * s, H - (h + h * val)),
                ((place + 1) * s, H - (h + h * val)),
                ((place + 1) * s, H - h),
                ((place + 0) * s, H - h),
            ]

        def horiz_ind(place, val):
            return [
                ((place + 0) * s, H - 4 * h),
                ((place + val) * s, H - 4 * h),
                ((place + val) * s, H - 2 * h),
                ((place + 0) * s, H - 2 * h),
            ]

        assert self.car is not None
        true_speed = np.sqrt(
            np.square(self.car.hull.linearVelocity[0])
            + np.square(self.car.hull.linearVelocity[1])
        )

        # simple wrapper to render if the indicator value is above a threshold
        def render_if_min(value, points, color):
            if abs(value) > 1e-4:
                pygame.draw.polygon(self.surf, points=points, color=color)

        render_if_min(true_speed, vertical_ind(5, 0.02 * true_speed), (255, 255, 255))
        # ABS sensors


SIZE = 0.02

# modified car class for the modified car racing environment
# changes car color to light gray and removes wheels to make it look more like a spaceship
class Rocket(Car):
    def __init__(self, world, init_angle, init_x, init_y):
        super().__init__(world, init_angle, init_x, init_y)
        self.drawlist = self.drawlist[4:]
        self.hull.color = (0.8, 0.8, 0.8)


# register the new environment so it can be used
register(
    id='CustomCarRacing-V0',
    entry_point='custom_carRacing:customCarRacing',
    max_episode_steps=500,
)