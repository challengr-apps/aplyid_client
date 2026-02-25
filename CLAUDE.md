# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Aplyid is an Elixir API client library for the [APLYiD Developer API](https://docs.aplyid.com/). It follows standard OTP application conventions with a supervision tree.

## Common Commands

- **Compile**: `mix compile`
- **Run tests**: `mix test`
- **Run a single test file**: `mix test test/aplyid_test.exs`
- **Run a single test by line**: `mix test test/aplyid_test.exs:5`
- **Format code**: `mix format`
- **Check formatting**: `mix format --check-formatted`
- **Fetch dependencies**: `mix deps.get`

## Architecture

- **Elixir 1.18+ / OTP 28** project built with Mix
- **OTP Application**: `Aplyid.Application` starts a supervisor with `:one_for_one` strategy
- **Module namespace**: All modules live under `Aplyid.*`
- **Testing**: ExUnit with doctests enabled
