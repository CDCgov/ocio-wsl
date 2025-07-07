# [2.5.0](https://github.com/cdcent/ocio-wsl/compare/2.4.0...2.5.0) (2025-07-07)


### Features

* upgrading os packages and mise tools ([#83](https://github.com/cdcent/ocio-wsl/issues/83)) ([45a4033](https://github.com/cdcent/ocio-wsl/commit/45a40339c812b730c482f41e7e9acece542a5cb1))

# [2.4.0](https://github.com/cdcent/ocio-wsl/compare/2.3.0...2.4.0) (2025-04-09)


### Features

* Edso 2238 configure dns ([#81](https://github.com/cdcent/ocio-wsl/issues/81)) ([615b77d](https://github.com/cdcent/ocio-wsl/commit/615b77d89f76c620e6a982e725e84025c1f40042))

# [2.3.0](https://github.com/cdcent/ocio-wsl/compare/2.2.1...2.3.0) (2025-04-03)


### Features

* EDSO-1089 add default user on startup ([#80](https://github.com/cdcent/ocio-wsl/issues/80)) ([063fb69](https://github.com/cdcent/ocio-wsl/commit/063fb697d2dee8d4fff3d5a62ff4ce44c0ff7067))

## [2.2.1](https://github.com/cdcent/ocio-wsl/compare/2.2.0...2.2.1) (2025-04-01)


### Bug Fixes

* updating dependencies, ordering dependencies for mise ([#76](https://github.com/cdcent/ocio-wsl/issues/76)) ([08d4719](https://github.com/cdcent/ocio-wsl/commit/08d47198ad87634ba6848141896b8b70f5fe6ef5))

# [2.2.0](https://github.com/cdcent/ocio-wsl/compare/2.1.0...2.2.0) (2025-03-11)


### Features

* use mise instead of asdf ([#72](https://github.com/cdcent/ocio-wsl/issues/72)) ([0324327](https://github.com/cdcent/ocio-wsl/commit/03243273da76d86dd53ba22d7ad685670d7ecdf2))

# [2.1.0](https://github.com/cdcent/ocio-wsl/compare/2.0.2...2.1.0) (2024-12-19)


### Bug Fixes

* add sudo to default plugin, so that new users can have superpowers ([fa1c655](https://github.com/cdcent/ocio-wsl/commit/fa1c65512c0907c011dfca57a4e06b0008fba2c3))
* adding default path and testing ([6a9ddb6](https://github.com/cdcent/ocio-wsl/commit/6a9ddb644cdd0845a39a88aac6dfdfd74dfee129))
* creating the asdf directory to ensure it is there ([8f539c5](https://github.com/cdcent/ocio-wsl/commit/8f539c50b5bc4835e7d3a59d5cbc42c7bd7c68c4))
* ensuring we end the quote properly ([4f9373f](https://github.com/cdcent/ocio-wsl/commit/4f9373faa1d14c56990dc31520ea251a490009d5))
* fixing asdf's brokeness ([3454dfd](https://github.com/cdcent/ocio-wsl/commit/3454dfd4f01239f49dad402aa84d677f364fa662))
* removing sudo usage and properly adding a new user to login ([b954731](https://github.com/cdcent/ocio-wsl/commit/b9547313193c02d0300d0160afd4bff5fd07aa6e))
* setting up default bash scripts for new user in Linux ([c59fa1e](https://github.com/cdcent/ocio-wsl/commit/c59fa1e1ec6e59463f4d39f867e31c1e30d20e15))
* simple cleanup ([666fc5e](https://github.com/cdcent/ocio-wsl/commit/666fc5e12c30fd0f14a1bb5736d09b8e9dd7908e))


### Features

* default bashrc files for new user in distro ([eb39667](https://github.com/cdcent/ocio-wsl/commit/eb39667378a3f3d2ea410a39821e0c39241a66c9))
* new user creation and folder restructuring ([4f7c487](https://github.com/cdcent/ocio-wsl/commit/4f7c4876e3cc122db3e73da77270da846b8e81c9))
* updating README with other WSL implementations ([2889d37](https://github.com/cdcent/ocio-wsl/commit/2889d37de54e605b64d76fdfe6bc0cf5da6c453e))

## [2.0.2](https://github.com/cdcent/ocio-wsl/compare/2.0.1...2.0.2) (2024-12-17)


### Bug Fixes

* updating dockerfile date ([f3fedd0](https://github.com/cdcent/ocio-wsl/commit/f3fedd08b0ef62ccc9a5fa07ffabd51e48ad35c3))
* updating python version ([ced58da](https://github.com/cdcent/ocio-wsl/commit/ced58da40f5ab8347d2e4beb73181013f797d125))

## [2.0.1](https://github.com/cdcent/ocio-wsl/compare/2.0.0...2.0.1) (2024-11-02)


### Bug Fixes

* **doc:** update the README ([a434089](https://github.com/cdcent/ocio-wsl/commit/a434089b3dbd3468e6170eb1662ef4e18bc48021))

# [2.0.0](https://github.com/cdcent/ocio-wsl/compare/1.0.11...2.0.0) (2024-09-23)


### Features

* Dev/upgrade to ubuntu 24.04 (Waiting on 24.04.01 release) ([#47](https://github.com/cdcent/ocio-wsl/issues/47)) ([75096ea](https://github.com/cdcent/ocio-wsl/commit/75096ea141baaedd983269e3f5f2e8675b86d637))


### BREAKING CHANGES

* Upgrade to Ubuntu 24.04

* chore[update]: updating dependencies, add shellcheck

* chore[update]: update semantic versioning

## [1.0.11](https://github.com/cdcent/ocio-wsl/compare/1.0.10...1.0.11) (2024-07-22)


### Bug Fixes

* setting up certificate trust by default for basic languages ([#43](https://github.com/cdcent/ocio-wsl/issues/43)) ([cccb1b6](https://github.com/cdcent/ocio-wsl/commit/cccb1b6517b9ed1f4af4a4ccd17de9520302c614))

## [1.0.10](https://github.com/cdcent/ocio-wsl/compare/1.0.9...1.0.10) (2024-07-22)


### Bug Fixes

* updating to the latest supported tools version ([#42](https://github.com/cdcent/ocio-wsl/issues/42)) ([1d36b8d](https://github.com/cdcent/ocio-wsl/commit/1d36b8d8eb9e56f0125e2cfe39279f3da9833477))

## [1.0.9](https://github.com/cdcent/ocio-wsl/compare/1.0.8...1.0.9) (2024-06-20)


### Bug Fixes

* dependencies update for tools and package ([#38](https://github.com/cdcent/ocio-wsl/issues/38)) ([20e75b6](https://github.com/cdcent/ocio-wsl/commit/20e75b61993e64e5f3dd3341250b4072e5a8a420))
* fixing deployment by not persisting checkout token ([#40](https://github.com/cdcent/ocio-wsl/issues/40)) ([a30bbe0](https://github.com/cdcent/ocio-wsl/commit/a30bbe09f7509920c70b0c5a74428958d8749340))

## [1.0.8](https://github.com/cdcent/ocio-wsl/compare/1.0.7...1.0.8) (2024-04-11)


### Bug Fixes

* adding extra tools installation as a test ([#34](https://github.com/cdcent/ocio-wsl/issues/34)) ([33f219c](https://github.com/cdcent/ocio-wsl/commit/33f219c43e32fa1a289d674c8ed44da0f2421091))
* **workflow:** avoid running dryrun if not in a Pull Request ([#35](https://github.com/cdcent/ocio-wsl/issues/35)) ([09f6ca0](https://github.com/cdcent/ocio-wsl/commit/09f6ca03fe35aed422f3e57fdd006ba62f503fae))
* **workflow:** reordering and providing greater permissions ([#37](https://github.com/cdcent/ocio-wsl/issues/37)) ([756d953](https://github.com/cdcent/ocio-wsl/commit/756d953a986639ba7c831b702b0703543aa96b66))

## [1.0.7](https://github.com/cdcent/ocio-wsl/compare/1.0.6...1.0.7) (2024-03-16)


### Bug Fixes

* adding ripgrep and r, fixing yarn ([#29](https://github.com/cdcent/ocio-wsl/issues/29)) ([46c14b0](https://github.com/cdcent/ocio-wsl/commit/46c14b0e90d47ae5bf2d9e8e0a1c0d84fbb4a6bb))

## [1.0.6](https://github.com/cdcent/ocio-wsl/compare/1.0.5...1.0.6) (2024-03-11)


### Bug Fixes

* dependencies update based on latest provided dependencies ([#28](https://github.com/cdcent/ocio-wsl/issues/28)) ([57d155c](https://github.com/cdcent/ocio-wsl/commit/57d155c454813645edf5eab07c95d71b696e8eed))

## [1.0.5](https://github.com/cdcent/ocio-wsl/compare/1.0.4...1.0.5) (2024-02-29)


### Bug Fixes

* adding deployment cron job ([#25](https://github.com/cdcent/ocio-wsl/issues/25)) ([54ea624](https://github.com/cdcent/ocio-wsl/commit/54ea624d5f306140df94b1e2d28c745fc978890e))

## [1.0.4](https://github.com/cdcent/ocio-wsl/compare/1.0.3...1.0.4) (2023-12-03)


### Bug Fixes

* bump version and add troubleshoot link ([#22](https://github.com/cdcent/ocio-wsl/issues/22)) ([29f79ba](https://github.com/cdcent/ocio-wsl/commit/29f79ba31c56f8d749f0a241922be1893b70c8fd))
* magenta color for terminal directory, fix time change script, update README ([#23](https://github.com/cdcent/ocio-wsl/issues/23)) ([f8fa80d](https://github.com/cdcent/ocio-wsl/commit/f8fa80d84245b44c8857b9cf3869c7da29916a86))

## [1.0.3](https://github.com/cdcent/ocio-wsl/compare/1.0.2...1.0.3) (2023-11-22)


### Bug Fixes

* set python to global usage and clean up documentation ([#18](https://github.com/cdcent/ocio-wsl/issues/18)) ([523381c](https://github.com/cdcent/ocio-wsl/commit/523381c288d23805900a44e209a2f341d2d0e286))

## [1.0.2](https://github.com/cdcent/ocio-wsl/compare/1.0.1...1.0.2) (2023-11-22)


### Bug Fixes

* generating checksums for ubuntu image ([#17](https://github.com/cdcent/ocio-wsl/issues/17)) ([4780219](https://github.com/cdcent/ocio-wsl/commit/47802190f735789486fd5a1421ed0e9e7c891ac2))

## [1.0.1](https://github.com/cdcent/ocio-wsl/compare/1.0.0...1.0.1) (2023-11-20)


### Bug Fixes

* upgrading dev tools baseline, include python 3.11 support ([#16](https://github.com/cdcent/ocio-wsl/issues/16)) ([c50b27c](https://github.com/cdcent/ocio-wsl/commit/c50b27c8b9b129553a3a9eb397487832259203a4))

# 1.0.0 (2023-11-13)


### Bug Fixes

* distro for semantic release ([#14](https://github.com/cdcent/ocio-wsl/issues/14)) ([aa75a99](https://github.com/cdcent/ocio-wsl/commit/aa75a99aec08f2b508fb4456e3f96801836f0a4d))


### Features

* bumping feature version ([#13](https://github.com/cdcent/ocio-wsl/issues/13)) ([b3d870e](https://github.com/cdcent/ocio-wsl/commit/b3d870e267e0899bfd63804a8ce157a0c3e438ef))
