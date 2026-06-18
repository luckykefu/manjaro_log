```
config
  config.toml
src
  main.rs # 只做入口
  cli.rs # --config/-c 指定配置文件路径
  lib.rs # 只做导出
  error.rs # thiserror 库
  runner/
    config.rs # config-rs 库,从文件反序列化AppConfig, AppConfig::from_file()默认: env!("CARGO_MANIFEST_DIR")/config/config.toml
    mod.rs
    runner.rs # 逻辑编排
  run_once/
    config.rs # RunOnceConfig
    mod.rs
    run_once.rs # 单次逻辑编排
```
