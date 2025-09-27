// Lyvoxa — Stellar system monitor
// Copyright (c) 2025 Rezky Nightky
// Licensed under GPL-3.0-or-later. See LICENSE in project root.

use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEvent},
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
use obfstr::obfstr;
use ratatui::{
    Frame, Terminal,
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    symbols,
    widgets::{
        Axis, Block, Borders, Chart, Clear, Dataset, Gauge, Paragraph, Row, Table, TableState,
    },
};
use serde::{Deserialize, Serialize};
use std::{
    collections::{HashSet, VecDeque},
    env,
    error::Error,
    fs, io,
    path::{Path, PathBuf},
    time::{Duration, Instant},
};
use tokio::time::MissedTickBehavior;

mod monitor;
use monitor::SystemMonitor;
mod theme;
use theme::{Theme, ThemeKind};
mod plugin;

const VERSION: &str = env!("CARGO_PKG_VERSION");
const NAME: &str = env!("CARGO_PKG_NAME");

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum SortKey {
    Cpu,
    Mem,
    Pid,
    User,
    Command,
}

fn load_config_file_with_flag() -> (AppConfig, bool, PathBuf, ConfigSource) {
    let (path, source) = resolve_config_path();
    let existed = path.exists();
    if let Ok(content) = fs::read_to_string(&path)
        && let Ok(cfg) = toml::from_str::<AppConfig>(&content)
    {
        return (cfg, existed, path, source);
    }
    (AppConfig::default(), existed, path, source)
}

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum Overlay {
    None,
    Help,
    Setup,
    Search,
    Filter,
    #[allow(dead_code)]
    Export,
    Insights,
}

fn print_help() {
    println!(
        "🌟 {} v{} - An optimized monitoring system linux",
        NAME, VERSION
    );
    println!();
    println!("USAGE:");
    println!("    {} [OPTIONS]", NAME);
    println!();
    println!("OPTIONS:");
    println!("    -h, --help       Show this help message");
    println!("    -V, --version    Show version information");
    println!();
    println!("DESCRIPTION:");
    println!("    Futuristic TUI system monitor with AI-powered insights");
    println!("    - Real-time CPU, memory, network monitoring with charts");
    println!("    - Process management with interactive controls");
    println!("    - Three elite themes: Dark, Stellar, Matrix");
    println!();
    println!("EXAMPLES:");
    println!("    {} --help       Show this help message", NAME);
    println!();
    println!();
    println!("KEYBOARD SHORTCUTS:");
    println!("    F1  Help         F6  Sort modes     F11 Export data");
    println!("    F2  Setup        F7  Nice decrease  F12 AI Insights");
    println!("    F3  Search       F8  Nice increase  ESC Close overlays");
    println!("    F4  Filter       F9  Kill process   ");
    println!("    F5  Charts toggle F10 Quit         Tab Cycle themes");
    println!();
    println!("CONFIGURATION:");
    println!("    Precedence (highest to lowest):");
    println!("      1) LYVOXA_CONFIG=/path/to/config.toml");
    println!("      2) ./lyvoxa.toml | ./lyvoxa/config.toml | ./config/lyvoxa.toml");
    println!("      3) ./config.toml (only if valid Lyvoxa AppConfig)");
    println!("      4) /etc/lyvoxa/config.toml");
    println!("      5) ~/.config/lyvoxa/config.toml (XDG)");
    println!(
        "    Session-only env overrides: LYVOXA_UI_MS, LYVOXA_DATA_MS, LYVOXA_ROWS, LYVOXA_SHOW_CHARTS"
    );
    println!("    Keys persist: Theme (Tab), Sort (F6), Charts (F5), Rows (from file)");
    println!();
    println!("REPOSITORY:");
    println!("    https://github.com/oxyzenQ/lyvoxa");
}

fn print_version() {
    println!("{} {}", NAME, VERSION);
}

// Disable core dumps to make memory dumping harder (Linux only)
#[cfg(target_os = "linux")]
fn harden_process() {
    unsafe {
        // Best-effort; ignore errors
        libc::prctl(libc::PR_SET_DUMPABLE, 0, 0, 0, 0);
    }
}

// No-op on non-Linux targets
#[cfg(not(target_os = "linux"))]
fn harden_process() {}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // Handle command line arguments
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        match args[1].as_str() {
            "-h" | "--help" => {
                print_help();
                return Ok(());
            }
            "-V" | "--version" => {
                print_version();
                return Ok(());
            }
            _ => {
                eprintln!("Unknown option: {}", args[1]);
                eprintln!("Use --help for usage information");
                std::process::exit(1);
            }
        }
    }
    // Apply runtime hardening early
    harden_process();
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app and run it
    let app = App::new();
    let res = run_app(&mut terminal, app).await;

    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("{:?}", err)
    }

    Ok(())
}

// Configuration for runtime behavior, tunable via environment variables
//  - LYVOXA_UI_MS: UI redraw interval (ms), default 500
//  - LYVOXA_DATA_MS: System data refresh interval (ms), default 5000
//  - LYVOXA_ROWS: Max process rows displayed, default 15
//  - LYVOXA_SHOW_CHARTS: "1"/"true" to show charts (default), "0"/"false" to hide
#[derive(Debug, Clone, Serialize, Deserialize)]
struct AppConfig {
    ui_rate_ms: u64,
    data_rate_ms: u64,
    max_rows: usize,
    show_charts: bool,
    theme: Option<String>,
    sort: Option<String>,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            ui_rate_ms: 500,
            data_rate_ms: 5000,
            max_rows: 15,
            show_charts: true,
            theme: None,
            sort: None,
        }
    }
}

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
enum ConfigSource {
    Env,
    RepoLyvoxaToml,
    RepoLyvoxaDir,
    RepoConfigLyvoxaToml,
    RepoGenericToml,
    System,
    Xdg,
}

fn config_source_label(src: ConfigSource) -> &'static str {
    match src {
        ConfigSource::Env => "Env",
        ConfigSource::RepoLyvoxaToml => "Local (lyvoxa.toml)",
        ConfigSource::RepoLyvoxaDir => "Local (lyvoxa/config.toml)",
        ConfigSource::RepoConfigLyvoxaToml => "Local (config/lyvoxa.toml)",
        ConfigSource::RepoGenericToml => "Local (config.toml)",
        ConfigSource::System => "System (/etc)",
        ConfigSource::Xdg => "XDG (~/.config)",
    }
}

fn discover_config_candidates() -> Vec<(PathBuf, ConfigSource)> {
    let mut out: Vec<(PathBuf, ConfigSource)> = Vec::new();
    let mut seen: HashSet<String> = HashSet::new();

    let mut push_unique = |p: PathBuf, src: ConfigSource| {
        let key = p.display().to_string();
        if seen.insert(key) {
            out.push((p, src));
        }
    };

    // Env explicit
    if let Ok(p) = env::var("LYVOXA_CONFIG") {
        push_unique(PathBuf::from(p), ConfigSource::Env);
    }

    // Repo-local candidates (prefer lyvoxa-specific)
    if let Ok(cwd) = env::current_dir() {
        push_unique(cwd.join("lyvoxa.toml"), ConfigSource::RepoLyvoxaToml);
        push_unique(
            cwd.join("lyvoxa").join("config.toml"),
            ConfigSource::RepoLyvoxaDir,
        );
        push_unique(
            cwd.join("config").join("lyvoxa.toml"),
            ConfigSource::RepoConfigLyvoxaToml,
        );
        let generic = cwd.join("config.toml");
        if generic.exists()
            && let Ok(s) = fs::read_to_string(&generic)
            && toml::from_str::<AppConfig>(&s).is_ok()
        {
            push_unique(generic, ConfigSource::RepoGenericToml);
        }
    }

    // System-wide
    let sys = PathBuf::from("/etc/lyvoxa/config.toml");
    if sys.exists() {
        push_unique(sys, ConfigSource::System);
    }

    // XDG default
    let base = env::var("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            let mut home = env::var("HOME")
                .map(PathBuf::from)
                .unwrap_or_else(|_| PathBuf::from("."));
            home.push(".config");
            home
        });
    let mut xdg = base;
    xdg.push("lyvoxa");
    xdg.push("config.toml");
    push_unique(xdg, ConfigSource::Xdg);

    out
}

fn resolve_config_path() -> (PathBuf, ConfigSource) {
    // Highest priority: explicit path via env
    if let Ok(p) = env::var("LYVOXA_CONFIG") {
        return (PathBuf::from(p), ConfigSource::Env);
    }
    // Next: project-local config (useful when running from repo)
    if let Ok(cwd) = env::current_dir() {
        // Prefer lyvoxa-specific names to avoid collisions
        let candidates: [(PathBuf, ConfigSource); 4] = [
            (cwd.join("lyvoxa.toml"), ConfigSource::RepoLyvoxaToml),
            (
                cwd.join("lyvoxa").join("config.toml"),
                ConfigSource::RepoLyvoxaDir,
            ),
            (
                cwd.join("config").join("lyvoxa.toml"),
                ConfigSource::RepoConfigLyvoxaToml,
            ),
            (cwd.join("config.toml"), ConfigSource::RepoGenericToml),
        ];

        for (cand, src) in candidates {
            if cand.exists() {
                if src == ConfigSource::RepoGenericToml {
                    // Validate generic config.toml by parsing as AppConfig
                    if let Ok(s) = fs::read_to_string(&cand) {
                        if toml::from_str::<AppConfig>(&s).is_ok() {
                            return (cand, src);
                        } else {
                            // Not a Lyvoxa config; skip
                            continue;
                        }
                    } else {
                        continue;
                    }
                } else {
                    // lyvoxa.toml or lyvoxa/config.toml or config/lyvoxa.toml
                    return (cand, src);
                }
            }
        }
    }
    // System-wide fallback (enterprise use)
    let sys = PathBuf::from("/etc/lyvoxa/config.toml");
    if sys.exists() {
        return (sys, ConfigSource::System);
    }
    // Fallback: XDG Base Directory spec
    let base = env::var("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            let mut home = env::var("HOME")
                .map(PathBuf::from)
                .unwrap_or_else(|_| PathBuf::from("."));
            home.push(".config");
            home
        });
    let mut p = base;
    p.push("lyvoxa");
    p.push("config.toml");
    (p, ConfigSource::Xdg)
}

fn save_config_file_at(path: &Path, cfg: &AppConfig) -> io::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let data = toml::to_string_pretty(cfg).unwrap_or_else(|_| String::new());
    fs::write(path, data)
}

struct App {
    monitor: SystemMonitor,
    should_quit: bool,
    cpu_history: VecDeque<f64>,
    memory_history: VecDeque<f64>,
    net_rx_history: VecDeque<f64>,
    net_tx_history: VecDeque<f64>,
    last_update: Instant,
    theme_kind: ThemeKind,
    theme: Theme,
    overlay: Overlay,
    input_buffer: String,
    filter: String,
    search: String,
    sort_key: SortKey,
    selected: usize,
    status_message: Option<String>,
    config: AppConfig,
    config_path: PathBuf,
    config_source: ConfigSource,
    setup_sources: Vec<(PathBuf, ConfigSource)>,
    setup_selected: usize,
}

impl App {
    fn new() -> App {
        // Start with defaults, overlay file config, then env overrides into an effective config.
        let (file_cfg, existed, cfg_path, cfg_src) = load_config_file_with_flag();
        let mut config = file_cfg.clone();
        if let Ok(v) = env::var("LYVOXA_UI_MS")
            && let Ok(ms) = v.parse::<u64>()
        {
            config.ui_rate_ms = ms;
        }
        if let Ok(v) = env::var("LYVOXA_DATA_MS")
            && let Ok(ms) = v.parse::<u64>()
        {
            config.data_rate_ms = ms;
        }
        if let Ok(v) = env::var("LYVOXA_ROWS")
            && let Ok(n) = v.parse::<usize>()
        {
            config.max_rows = n;
        }
        if let Ok(v) = env::var("LYVOXA_SHOW_CHARTS") {
            let v = v.to_lowercase();
            config.show_charts = !(v == "0" || v == "false");
        }

        // Map config theme/sort to runtime enums with robust defaults
        let theme_kind = match config.theme.as_deref() {
            Some("dark") => ThemeKind::Dark,
            Some("matrix") => ThemeKind::Matrix,
            Some("stellar") => ThemeKind::Stellar,
            _ => ThemeKind::Stellar,
        };
        let sort_key = match config.sort.as_deref() {
            Some("mem") => SortKey::Mem,
            Some("pid") => SortKey::Pid,
            Some("user") => SortKey::User,
            Some("command") => SortKey::Command,
            Some("cpu") => SortKey::Cpu,
            _ => SortKey::Cpu,
        };

        // Ensure config file exists on first run (write only file defaults, not env overrides)
        if !existed {
            let _ = save_config_file_at(&cfg_path, &file_cfg);
        }

        App {
            monitor: SystemMonitor::new(),
            should_quit: false,
            cpu_history: VecDeque::with_capacity(30),
            memory_history: VecDeque::with_capacity(30),
            net_rx_history: VecDeque::with_capacity(30),
            net_tx_history: VecDeque::with_capacity(30),
            last_update: Instant::now(),
            theme_kind,
            theme: Theme::palette(theme_kind),
            overlay: Overlay::None,
            input_buffer: String::new(),
            filter: String::new(),
            search: String::new(),
            sort_key,
            selected: 0,
            status_message: None,
            config,
            config_path: cfg_path,
            config_source: cfg_src,
            setup_sources: Vec::new(),
            setup_selected: 0,
        }
    }

    fn refresh_config_candidates(&mut self) {
        self.setup_sources = discover_config_candidates();
        // Ensure current config is at top if not present
        if !self
            .setup_sources
            .iter()
            .any(|(p, _)| p.as_path() == self.config_path.as_path())
        {
            self.setup_sources
                .insert(0, (self.config_path.clone(), self.config_source));
        }
        self.setup_selected = 0;
    }

    fn apply_selected_config(&mut self) {
        if self.setup_sources.is_empty() {
            return;
        }
        let (path, source) = self.setup_sources[self.setup_selected].clone();
        // If file exists, try load; if not, create from current config
        if path.exists() {
            match fs::read_to_string(&path)
                .ok()
                .and_then(|s| toml::from_str::<AppConfig>(&s).ok())
            {
                Some(cfg) => {
                    self.config = cfg;
                    self.config_path = path;
                    self.config_source = source;
                    self.status_message =
                        Some(format!("Config switched: {}", self.config_path.display()));
                }
                None => {
                    self.status_message =
                        Some(format!("Invalid config, not switched: {}", path.display()));
                }
            }
        } else {
            // Create new file from current in-memory config
            if let Err(e) = save_config_file_at(&path, &self.config) {
                self.status_message = Some(format!(
                    "Failed to create config: {} ({})",
                    path.display(),
                    e
                ));
                return;
            }
            self.config_path = path;
            self.config_source = source;
            // Apply theme and sort from config to runtime
            self.theme_kind = match self.config.theme.as_deref() {
                Some("dark") => ThemeKind::Dark,
                Some("matrix") => ThemeKind::Matrix,
                _ => ThemeKind::Stellar,
            };
            self.theme = Theme::palette(self.theme_kind);
            self.sort_key = match self.config.sort.as_deref() {
                Some("mem") => SortKey::Mem,
                Some("pid") => SortKey::Pid,
                Some("user") => SortKey::User,
                Some("command") => SortKey::Command,
                _ => SortKey::Cpu,
            };
            self.status_message = Some(format!("Config switched: {}", self.config_path.display()));
        }
    }

    fn cycle_theme(&mut self, next: bool) {
        self.theme_kind = match (self.theme_kind, next) {
            // Forward cycling: Dark → Stellar → Matrix → Dark
            (ThemeKind::Dark, true) => ThemeKind::Stellar,
            (ThemeKind::Stellar, true) => ThemeKind::Matrix,
            (ThemeKind::Matrix, true) => ThemeKind::Dark,
            // Backward cycling: Dark → Matrix → Stellar → Dark
            (ThemeKind::Dark, false) => ThemeKind::Matrix,
            (ThemeKind::Stellar, false) => ThemeKind::Dark,
            (ThemeKind::Matrix, false) => ThemeKind::Stellar,
        };
        self.theme = Theme::palette(self.theme_kind);

        // Add smooth transition effect (status message)
        self.status_message = Some(format!("🎨 Theme switched to: {:?}", self.theme_kind));

        // Persist theme to config file
        self.config.theme = Some(match self.theme_kind {
            ThemeKind::Dark => "dark".to_string(),
            ThemeKind::Stellar => "stellar".to_string(),
            ThemeKind::Matrix => "matrix".to_string(),
        });
        let _ = save_config_file_at(&self.config_path, &self.config);
    }

    fn export_snapshot(&mut self) {
        use chrono::{DateTime, Local};

        let now: DateTime<Local> = Local::now();
        let timestamp = now.format("%Y%m%d_%H%M%S").to_string();
        let filename = format!("lyvoxa_snapshot_{}.json", timestamp);

        // Collect current system data
        let cpu_usage = if let Some(&last_cpu) = self.cpu_history.back() {
            last_cpu
        } else {
            0.0
        };
        let memory_usage = if let Some(&last_mem) = self.memory_history.back() {
            last_mem
        } else {
            0.0
        };
        let (net_rx, net_tx) = if let (Some(&rx), Some(&tx)) =
            (self.net_rx_history.back(), self.net_tx_history.back())
        {
            (rx, tx)
        } else {
            (0.0, 0.0)
        };

        let top_processes = self.collect_processes(5); // Reduced from 10 to 5

        let snapshot_data = format!(
            r#"{{
  "timestamp": "{}",
  "version": "{}",
  "theme": "{:?}",
  "system_metrics": {{
    "cpu_usage_percent": {:.2},
    "memory_usage_percent": {:.2},
    "network_rx_bytes_per_sec": {:.2},
    "network_tx_bytes_per_sec": {:.2}
  }},
  "top_processes": [{}
  ]
}}"#,
            now.format("%Y-%m-%d %H:%M:%S"),
            VERSION,
            self.theme_kind,
            cpu_usage,
            memory_usage,
            net_rx,
            net_tx,
            top_processes
                .iter()
                .map(|p| format!(
                    r#"
    {{
      "pid": {},
      "user": "{}",
      "command": "{}",
      "cpu_percent": {:.2},
      "memory_bytes": {}
    }}"#,
                    p.pid, p.user, p.command, p.cpu_usage, p.mem_bytes
                ))
                .collect::<Vec<_>>()
                .join(",")
        );

        match fs::write(&filename, snapshot_data) {
            Ok(_) => {
                self.status_message = Some(format!("📄 Snapshot exported to: {}", filename));
            }
            Err(e) => {
                self.status_message = Some(format!("❌ Export failed: {}", e));
            }
        }
    }

    fn show_ai_insights(&mut self) {
        // AI-assisted insights based on current system state
        let mut insights = Vec::new();

        let cpu_usage = if let Some(&last_cpu) = self.cpu_history.back() {
            last_cpu
        } else {
            0.0
        };
        let memory_usage = if let Some(&last_mem) = self.memory_history.back() {
            last_mem
        } else {
            0.0
        };
        let top_processes = self.collect_processes(3); // Only need top 3 for insights

        // CPU Analysis
        if cpu_usage > 80.0 {
            insights.push("⚠️  HIGH CPU: System under heavy load".to_string());
            if let Some(proc) = top_processes.first()
                && proc.cpu_usage > 50.0
            {
                insights.push(format!(
                    "🔥 Top CPU hog: {} ({:.1}%)",
                    proc.command, proc.cpu_usage
                ));
            }
        } else if cpu_usage < 10.0 {
            insights.push("✅ CPU: System running efficiently".to_string());
        }

        // Memory Analysis
        if memory_usage > 85.0 {
            insights.push("⚠️  HIGH MEMORY: Consider closing applications".to_string());
            if let Some(proc) = top_processes.iter().max_by_key(|p| p.mem_bytes) {
                let mem_mb = proc.mem_bytes / (1024 * 1024);
                insights.push(format!("💾 Memory hog: {} ({} MB)", proc.command, mem_mb));
            }
        } else if memory_usage < 50.0 {
            insights.push("✅ MEMORY: Plenty of free memory available".to_string());
        }

        // Process Analysis
        let high_cpu_procs: Vec<_> = top_processes
            .iter()
            .filter(|p| p.cpu_usage > 20.0)
            .collect();
        if high_cpu_procs.len() > 3 {
            insights.push("⚡ Multiple high-CPU processes detected".to_string());
        }

        // Network Analysis
        if let (Some(&rx), Some(&tx)) = (self.net_rx_history.back(), self.net_tx_history.back()) {
            let total_mb_s = (rx + tx) / (1024.0 * 1024.0);
            if total_mb_s > 10.0 {
                insights.push(format!("🌐 HIGH NETWORK: {:.1} MB/s total", total_mb_s));
            }
        }

        // Performance recommendations
        if cpu_usage > 70.0 && memory_usage > 70.0 {
            insights.push("💡 RECOMMENDATION: System bottleneck detected".to_string());
            insights.push("   → Consider upgrading hardware or closing applications".to_string());
        } else if cpu_usage > 70.0 {
            insights.push("💡 RECOMMENDATION: CPU-bound workload".to_string());
            insights.push("   → Check for background processes or heavy computations".to_string());
        } else if memory_usage > 70.0 {
            insights.push("💡 RECOMMENDATION: Memory pressure".to_string());
            insights.push("   → Close unused applications or browser tabs".to_string());
        }

        if insights.is_empty() {
            insights.push("✨ SYSTEM OPTIMAL: Everything looks good!".to_string());
            insights.push("🚀 Performance is within normal ranges".to_string());
        }

        self.overlay = Overlay::Insights;
        self.status_message = Some(insights.join("\n"));
    }

    fn update(&mut self) {
        // Refresh system data
        self.monitor.refresh();

        // Update CPU history - reduced buffer size
        let cpu_usage = self.monitor.get_global_cpu_usage();
        self.cpu_history.push_back(cpu_usage);
        if self.cpu_history.len() > 30 {
            // Further reduced to 30 points
            self.cpu_history.pop_front();
        }

        // Update memory history - further reduced buffer size
        let memory_usage = self.monitor.get_memory_usage_percent();
        self.memory_history.push_back(memory_usage);
        if self.memory_history.len() > 30 {
            self.memory_history.pop_front();
        }

        // Update network history - further reduced buffer size
        let (rx, tx) = self.monitor.get_network_rates();
        self.net_rx_history.push_back(rx);
        self.net_tx_history.push_back(tx);
        if self.net_rx_history.len() > 30 {
            self.net_rx_history.pop_front();
        }
        if self.net_tx_history.len() > 30 {
            self.net_tx_history.pop_front();
        }

        self.last_update = Instant::now();
    }

    fn handle_key(&mut self, key: KeyEvent) {
        match self.overlay {
            Overlay::Search | Overlay::Filter => match key.code {
                KeyCode::Esc => {
                    self.overlay = Overlay::None;
                    self.input_buffer.clear();
                }
                KeyCode::Enter => {
                    match self.overlay {
                        Overlay::Search => {
                            self.search = self.input_buffer.clone();
                        }
                        Overlay::Filter => {
                            self.filter = self.input_buffer.clone();
                        }
                        _ => {}
                    }
                    self.overlay = Overlay::None;
                    self.input_buffer.clear();
                }
                KeyCode::Backspace => {
                    self.input_buffer.pop();
                }
                KeyCode::Char(c) => {
                    self.input_buffer.push(c);
                }
                _ => {}
            },
            Overlay::Setup => match key.code {
                KeyCode::Esc => {
                    self.overlay = Overlay::None;
                }
                KeyCode::Up => {
                    if self.setup_selected > 0 {
                        self.setup_selected -= 1;
                    }
                }
                KeyCode::Down => {
                    if self.setup_selected + 1 < self.setup_sources.len() {
                        self.setup_selected += 1;
                    }
                }
                KeyCode::Enter => {
                    self.apply_selected_config();
                    self.overlay = Overlay::None;
                }
                KeyCode::Char('r') | KeyCode::Char('R') => {
                    self.refresh_config_candidates();
                }
                _ => {}
            },
            Overlay::Help | Overlay::Insights | Overlay::Export => match key.code {
                KeyCode::Esc | KeyCode::Enter => {
                    self.overlay = Overlay::None;
                }
                _ => {}
            },
            _ => {}
        }

        match key.code {
            KeyCode::Char('q') | KeyCode::F(10) => {
                let _ = save_config_file_at(&self.config_path, &self.config);
                self.should_quit = true
            }
            KeyCode::Up => {
                if self.selected > 0 {
                    self.selected -= 1;
                }
            }
            KeyCode::Down => {
                self.selected = self.selected.saturating_add(1);
            }
            KeyCode::F(1) => {
                self.overlay = Overlay::Help;
            }
            KeyCode::F(2) => {
                self.refresh_config_candidates();
                self.overlay = Overlay::Setup;
            }
            KeyCode::F(3) => {
                self.overlay = Overlay::Search;
                self.input_buffer = String::new();
            }
            KeyCode::F(4) => {
                self.overlay = Overlay::Filter;
                self.input_buffer = self.filter.clone();
            }
            KeyCode::F(5) => {
                self.config.show_charts = !self.config.show_charts;
                self.status_message = Some(if self.config.show_charts {
                    "Charts: ON".to_string()
                } else {
                    "Charts: OFF".to_string()
                });
                let _ = save_config_file_at(&self.config_path, &self.config);
            }
            KeyCode::F(6) => {
                self.sort_key = match self.sort_key {
                    SortKey::Cpu => SortKey::Mem,
                    SortKey::Mem => SortKey::Pid,
                    SortKey::Pid => SortKey::User,
                    SortKey::User => SortKey::Command,
                    SortKey::Command => SortKey::Cpu,
                };
                self.status_message = Some(format!("Sort: {:?}", self.sort_key));
                self.config.sort = Some(match self.sort_key {
                    SortKey::Cpu => "cpu".to_string(),
                    SortKey::Mem => "mem".to_string(),
                    SortKey::Pid => "pid".to_string(),
                    SortKey::User => "user".to_string(),
                    SortKey::Command => "command".to_string(),
                });
                let _ = save_config_file_at(&self.config_path, &self.config);
            }
            KeyCode::F(7) => {
                self.adjust_nice(false);
            }
            KeyCode::F(8) => {
                self.adjust_nice(true);
            }
            KeyCode::F(9) => {
                self.kill_selected();
            }
            KeyCode::F(11) => {
                self.export_snapshot();
            }
            KeyCode::F(12) => {
                self.show_ai_insights();
            }
            KeyCode::Tab => {
                self.cycle_theme(true);
            }
            _ => {}
        }
    }

    fn collect_processes(&self, limit: usize) -> Vec<monitor::ProcessInfo> {
        // Only get what we need + small buffer for filtering
        let fetch_limit = if self.filter.is_empty() {
            limit
        } else {
            limit * 2
        };
        let mut procs = self.monitor.get_top_processes(fetch_limit.min(50));

        // Filter first to reduce sorting overhead
        if !self.filter.is_empty() {
            let term = self.filter.to_lowercase();
            procs.retain(|p| {
                p.command.to_lowercase().contains(&term) || p.user.to_lowercase().contains(&term)
            });
        }

        // Sort only the processes we'll actually display
        match self.sort_key {
            SortKey::Cpu => procs.sort_by(|a, b| {
                b.cpu_usage
                    .partial_cmp(&a.cpu_usage)
                    .unwrap_or(std::cmp::Ordering::Equal)
            }),
            SortKey::Mem => procs.sort_by(|a, b| b.mem_bytes.cmp(&a.mem_bytes)),
            SortKey::Pid => procs.sort_by(|a, b| a.pid.cmp(&b.pid)),
            SortKey::User => procs.sort_by(|a, b| a.user.cmp(&b.user)),
            SortKey::Command => procs.sort_by(|a, b| a.command.cmp(&b.command)),
        }

        // Truncate to requested limit
        if procs.len() > limit {
            procs.truncate(limit);
        }
        procs
    }

    fn selected_pid(&self) -> Option<u32> {
        let list = self.collect_processes(self.config.max_rows); // respect config rows
        if list.is_empty() {
            return None;
        }
        let idx = self.selected.min(list.len().saturating_sub(1));
        Some(list[idx].pid)
    }

    fn adjust_nice(&mut self, increase: bool) {
        if let Some(pid) = self.selected_pid() {
            let res = if increase {
                self.monitor.nice_increase(pid)
            } else {
                self.monitor.nice_decrease(pid)
            };
            self.status_message = Some(match res {
                Ok(_) => format!("Nice adjusted for PID {}", pid),
                Err(e) => format!("Nice change failed: {}", e),
            });
        }
    }

    fn kill_selected(&mut self) {
        if let Some(pid) = self.selected_pid() {
            let res = self.monitor.kill_process(pid);
            self.status_message = Some(match res {
                Ok(_) => format!("Sent SIGTERM to PID {}", pid),
                Err(e) => format!("Kill failed: {}", e),
            });
        }
    }
}

async fn run_app<B: Backend>(terminal: &mut Terminal<B>, mut app: App) -> io::Result<()> {
    // Use tokio intervals to decouple UI/data/input and keep CPU low
    let mut ui_tick = tokio::time::interval(Duration::from_millis(app.config.ui_rate_ms));
    ui_tick.set_missed_tick_behavior(MissedTickBehavior::Skip);
    let mut data_tick = tokio::time::interval(Duration::from_millis(app.config.data_rate_ms));
    data_tick.set_missed_tick_behavior(MissedTickBehavior::Skip);
    let mut input_tick = tokio::time::interval(Duration::from_millis(25));
    input_tick.set_missed_tick_behavior(MissedTickBehavior::Skip);

    loop {
        tokio::select! {
            _ = ui_tick.tick() => {
                terminal
                    .draw(|f| ui(f, &app))
                    .map_err(|e| io::Error::other(e.to_string()))?;
            },
            _ = data_tick.tick() => {
                app.update();
            },
            _ = input_tick.tick() => {
                while crossterm::event::poll(Duration::from_millis(0))? {
                    if let Event::Key(key) = event::read()? {
                        app.handle_key(key);
                    }
                }
            },
        }

        if app.should_quit {
            return Ok(());
        }
    }
}

fn ui(f: &mut Frame, app: &App) {
    // Adaptive layout depending on charts toggle
    let mut vertical = vec![
        Constraint::Length(3), // Header
        Constraint::Length(7), // CPU and Memory gauges
        Constraint::Length(5), // Per-core gauges
    ];
    if app.config.show_charts {
        vertical.push(Constraint::Length(12)); // Charts
    }
    vertical.push(Constraint::Min(0)); // Process list

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints(vertical)
        .split(f.area());

    // Header
    let cfg_label = config_source_label(app.config_source);
    let cfg_file = app
        .config_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("?");
    let header_text = format!(
        "Lyvoxa v{} | Config: {} ({}) | Theme: {:?} | Sort: {:?} | Filter: {} | {}",
        VERSION,
        cfg_label,
        cfg_file,
        app.theme_kind,
        app.sort_key,
        if app.filter.is_empty() {
            "(none)".to_string()
        } else {
            app.filter.clone()
        },
        app.status_message.clone().unwrap_or_default()
    );
    let header = Paragraph::new(header_text)
        .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Lyvoxa - F1 Help | F5 Charts | F11 Export | F12 Insights | Tab Themes | F10 Quit")
                .style(Style::default().fg(app.theme.accent)),
        );
    f.render_widget(header, chunks[0]);

    // CPU and Memory info layout
    let info_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(chunks[1]);

    // CPU gauge
    let cpu_usage = app.monitor.get_global_cpu_usage();
    let cpu_gauge = Gauge::default()
        .block(Block::default().borders(Borders::ALL).title("CPU Usage"))
        .gauge_style(Style::default().fg(app.theme.cpu))
        .percent(cpu_usage as u16)
        .label(format!("{:.1}%", cpu_usage));
    f.render_widget(cpu_gauge, info_chunks[0]);

    // Memory gauge
    let memory_usage = app.monitor.get_memory_usage_percent();
    let (used_mem, total_mem) = app.monitor.get_memory_info();
    let memory_gauge = Gauge::default()
        .block(Block::default().borders(Borders::ALL).title("Memory Usage"))
        .gauge_style(Style::default().fg(app.theme.mem))
        .percent(memory_usage as u16)
        .label(format!(
            "{:.1}% ({}/{})",
            memory_usage,
            humansize::format_size(used_mem, humansize::DECIMAL),
            humansize::format_size(total_mem, humansize::DECIMAL)
        ));
    f.render_widget(memory_gauge, info_chunks[1]);

    // Per-core gauges (show up to 8 cores)
    let per_core = app.monitor.get_cpu_usage_per_core();
    let n = per_core.len().min(8);
    let grid = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(chunks[2]);
    // Left column 0..n/2, Right column n/2..n
    let halfway = n.div_ceil(2);
    let left_rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints(
            (0..halfway)
                .map(|_| Constraint::Length(1))
                .collect::<Vec<_>>(),
        )
        .split(grid[0]);
    let right_rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints(
            (0..(n - halfway))
                .map(|_| Constraint::Length(1))
                .collect::<Vec<_>>(),
        )
        .split(grid[1]);
    for (i, &val) in per_core.iter().take(halfway).enumerate() {
        let g = Gauge::default()
            .block(Block::default().title(format!("CPU{}", i)))
            .gauge_style(Style::default().fg(app.theme.cpu))
            .percent(val as u16)
            .label(format!("{:.0}%", val));
        f.render_widget(g, left_rows[i]);
    }
    for (i, &val) in per_core.iter().skip(halfway).take(n - halfway).enumerate() {
        let idx = i + halfway;
        let g = Gauge::default()
            .block(Block::default().title(format!("CPU{}", idx)))
            .gauge_style(Style::default().fg(app.theme.cpu))
            .percent(val as u16)
            .label(format!("{:.0}%", val));
        f.render_widget(g, right_rows[i]);
    }

    // Charts layout (CPU, Memory, Network)
    if app.config.show_charts {
        let chart_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Percentage(34),
                Constraint::Percentage(33),
                Constraint::Percentage(33),
            ])
            .split(chunks[3]);

        // CPU chart - only render if we have significant data
        if app.cpu_history.len() > 5 {
            let cpu_data: Vec<(f64, f64)> = app
                .cpu_history
                .iter()
                .enumerate()
                .step_by(2)
                .map(|(i, &cpu)| (i as f64, cpu))
                .collect();

            let datasets = vec![
                Dataset::default()
                    .name("CPU %")
                    .marker(symbols::Marker::Dot)
                    .style(Style::default().fg(Color::Yellow))
                    .data(&cpu_data),
            ];

            let cpu_chart = Chart::new(datasets)
                .block(Block::default().title("CPU History").borders(Borders::ALL))
                .x_axis(Axis::default().title("Time").bounds([0.0, 120.0]))
                .y_axis(Axis::default().title("Usage %").bounds([0.0, 100.0]));
            f.render_widget(cpu_chart, chart_chunks[0]);
        }

        // Memory chart - only render if we have significant data
        if app.memory_history.len() > 5 {
            let mem_data: Vec<(f64, f64)> = app
                .memory_history
                .iter()
                .enumerate()
                .step_by(2)
                .map(|(i, &mem)| (i as f64, mem))
                .collect();

            let datasets = vec![
                Dataset::default()
                    .name("Memory %")
                    .marker(symbols::Marker::Dot)
                    .style(Style::default().fg(Color::Green))
                    .data(&mem_data),
            ];

            let memory_chart = Chart::new(datasets)
                .block(
                    Block::default()
                        .title("Memory History")
                        .borders(Borders::ALL),
                )
                .x_axis(Axis::default().title("Time").bounds([0.0, 120.0]))
                .y_axis(Axis::default().title("Usage %").bounds([0.0, 100.0]));
            f.render_widget(memory_chart, chart_chunks[1]);
        }

        // Network chart (RX/TX bytes/sec)
        if !app.net_rx_history.is_empty() && !app.net_tx_history.is_empty() {
            let rx_data: Vec<(f64, f64)> = app
                .net_rx_history
                .iter()
                .enumerate()
                .map(|(i, &v)| (i as f64, v))
                .collect();
            let tx_data: Vec<(f64, f64)> = app
                .net_tx_history
                .iter()
                .enumerate()
                .map(|(i, &v)| (i as f64, v))
                .collect();
            let datasets = vec![
                Dataset::default()
                    .name("RX B/s")
                    .marker(symbols::Marker::Dot)
                    .style(Style::default().fg(app.theme.net_rx))
                    .data(&rx_data),
                Dataset::default()
                    .name("TX B/s")
                    .marker(symbols::Marker::Dot)
                    .style(Style::default().fg(app.theme.net_tx))
                    .data(&tx_data),
            ];
            let max_val = app
                .net_rx_history
                .iter()
                .chain(app.net_tx_history.iter())
                .cloned()
                .fold(1.0_f64, |m, v| m.max(v));
            let net_chart = Chart::new(datasets)
                .block(Block::default().title("Network B/s").borders(Borders::ALL))
                .x_axis(Axis::default().title("Time").bounds([0.0, 120.0]))
                .y_axis(
                    Axis::default()
                        .title("Bytes/s")
                        .bounds([0.0, max_val * 1.2]),
                );
            f.render_widget(net_chart, chart_chunks[2]);
        }
    }

    // Process list - only collect what fits on screen (configurable)
    let processes = app.collect_processes(app.config.max_rows);
    let selected = app.selected.min(processes.len().saturating_sub(1));
    let process_items: Vec<Row> = processes
        .iter()
        .enumerate()
        .map(|(idx, p)| {
            let fmt_time = format!(
                "{:02}:{:02}:{:02}",
                p.time_total_secs / 3600,
                (p.time_total_secs / 60) % 60,
                p.time_total_secs % 60
            );
            let row = Row::new(vec![
                p.nice.to_string(),
                p.priority.to_string(),
                p.pid.to_string(),
                p.user.clone(),
                p.command.clone(),
                fmt_time,
                humansize::format_size(p.mem_bytes, humansize::DECIMAL),
                format!("{:.1}", p.cpu_usage),
                humansize::format_size(p.virt, humansize::DECIMAL),
                humansize::format_size(p.res, humansize::DECIMAL),
                humansize::format_size(p.shr, humansize::DECIMAL),
                p.state.to_string(),
            ]);
            if idx == selected {
                row.style(Style::default().bg(app.theme.selection_bg))
            } else {
                row
            }
        })
        .collect();

    let process_table = Table::new(
        process_items,
        [
            Constraint::Length(4),  // NI
            Constraint::Length(4),  // PRI
            Constraint::Length(7),  // PID
            Constraint::Length(10), // USER
            Constraint::Min(24),    // COMMAND
            Constraint::Length(9),  // TIME
            Constraint::Length(10), // MEM
            Constraint::Length(7),  // CPU%
            Constraint::Length(10), // VIRT
            Constraint::Length(10), // RES
            Constraint::Length(10), // SHR
            Constraint::Length(3),  // S
        ],
    )
    .header(
        Row::new(vec![
            "NI", "PRI", "PID", "USER", "COMMAND", "TIME", "MEM", "CPU%", "VIRT", "RES", "SHR", "S",
        ])
        .style(Style::default().fg(app.theme.table_header)),
    )
    .block(
        Block::default()
            .borders(Borders::ALL)
            .title("Processes (F3 Search, F4 Filter, F6 Sort, F7/F8 Nice, F9 Kill)")
            .border_style(Style::default().fg(app.theme.accent)),
    )
    .row_highlight_style(
        Style::default()
            .bg(app.theme.selection_bg)
            .fg(app.theme.accent)
            .add_modifier(Modifier::BOLD),
    )
    .highlight_symbol(">> ");

    let mut table_state = TableState::default();
    table_state.select(Some(selected));
    let proc_idx = if app.config.show_charts { 4 } else { 3 };
    f.render_stateful_widget(process_table, chunks[proc_idx], &mut table_state);

    // Overlays
    match app.overlay {
        Overlay::Help => {
            let area = centered_rect(70, 60, f.area());
            let help_text = obfstr!(
                "🚀 LYVOXA STELLAR CONTROLS 🚀\n\nPROCESS MANAGEMENT:\nF1 Help      F6 Sort modes    F9 Kill process\nF2 Setup     F7 Nice decrease ↑↓ Navigate\nF3 Search    F8 Nice increase Enter/Esc dialogs\nF4 Filter    F10 Quit\nF5 Charts toggle\n\nADVANCED FEATURES:\nF11 Export snapshot (JSON)\nF12 AI System Insights\nTab Cycle themes (3 elite themes)\n\nELITE THEMES:\nDark → Stellar → Matrix (cycle with Tab)\n\nConfig: ~/.config/lyvoxa/config.toml\nPress ESC to close this help window"
            ).to_string();
            f.render_widget(Clear, area);
            let p = Paragraph::new(help_text)
                .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
                .block(
                    Block::default()
                        .borders(Borders::ALL)
                        .title("Help")
                        .style(Style::default().fg(app.theme.accent)),
                );
            f.render_widget(p, area);
        }
        Overlay::Setup => {
            let area = centered_rect(80, 70, f.area());
            f.render_widget(Clear, area);
            let mut lines = Vec::new();
            lines.push(format!(
                "Select config (↑/↓ navigate, Enter apply, r refresh, Esc close)\nCurrent: {} [{}]\n",
                app.config_path.display(), config_source_label(app.config_source)
            ));
            if app.setup_sources.is_empty() {
                lines.push("(no candidates found)".to_string());
            } else {
                for (i, (p, src)) in app.setup_sources.iter().enumerate() {
                    let marker = if i == app.setup_selected { ">" } else { " " };
                    lines.push(format!(
                        "{} [{}] {}",
                        marker,
                        config_source_label(*src),
                        p.display()
                    ));
                }
            }
            let p = Paragraph::new(lines.join("\n"))
                .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
                .block(
                    Block::default()
                        .borders(Borders::ALL)
                        .title("Setup - Config Sources")
                        .style(Style::default().fg(app.theme.accent)),
                );
            f.render_widget(p, area);
        }
        Overlay::Search => {
            let area = centered_rect(60, 30, f.area());
            let text = format!(
                "Search query: {}\nPress Enter to apply or Esc to cancel",
                app.input_buffer
            );
            f.render_widget(Clear, area);
            let p = Paragraph::new(text)
                .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
                .block(
                    Block::default()
                        .borders(Borders::ALL)
                        .title("Search")
                        .style(Style::default().fg(app.theme.accent)),
                );
            f.render_widget(p, area);
        }
        Overlay::Filter => {
            let area = centered_rect(60, 30, f.area());
            let text = format!(
                "Filter term: {}\nPress Enter to apply or Esc to cancel",
                app.input_buffer
            );
            f.render_widget(Clear, area);
            let p = Paragraph::new(text)
                .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
                .block(
                    Block::default()
                        .borders(Borders::ALL)
                        .title("Filter")
                        .style(Style::default().fg(app.theme.accent)),
                );
            f.render_widget(p, area);
        }
        Overlay::Insights => {
            let area = centered_rect(80, 70, f.area());
            let default_msg = "No insights available".to_string();
            let insights_text = app.status_message.as_ref().unwrap_or(&default_msg);
            f.render_widget(Clear, area);
            let p = Paragraph::new(insights_text.as_str())
                .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
                .block(
                    Block::default()
                        .borders(Borders::ALL)
                        .title("🤖 AI System Insights (Press Esc to close)")
                        .style(Style::default().fg(app.theme.accent)),
                )
                .wrap(ratatui::widgets::Wrap { trim: true });
            f.render_widget(p, area);
        }
        Overlay::Export => {
            let area = centered_rect(60, 30, f.area());
            let export_text = "📤 Exporting system snapshot...\n\nData will be saved as JSON with:\n• System metrics\n• Process information\n• Theme configuration";
            f.render_widget(Clear, area);
            let p = Paragraph::new(export_text)
                .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
                .block(
                    Block::default()
                        .borders(Borders::ALL)
                        .title("Export Snapshot")
                        .style(Style::default().fg(app.theme.accent)),
                );
            f.render_widget(p, area);
        }
        Overlay::None => {}
    }
}

fn centered_rect(
    percent_x: u16,
    percent_y: u16,
    r: ratatui::layout::Rect,
) -> ratatui::layout::Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);
    let vertical = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1]);
    vertical[1]
}
