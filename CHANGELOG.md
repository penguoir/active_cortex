# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.2: 2022-11-15

### Added:

- Generate has_many associations

### Changed:

- Move to RSpec instead of Minitest
- Refactor implementation

## 0.1.0: 2022-10-29

### Added

- Basic `ai_generated` macro which populates the field you give it using a generated prompt.
- Two options for generating the prompt, either pass a symbol or a proc.
- Configuration of OpenAI access token
