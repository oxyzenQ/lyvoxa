use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEvent},
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
use ratatui::{
    Frame, Terminal,
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::{Color, Style},
    symbols,
    widgets::{Axis, Block, Borders, Chart, Clear, Dataset, Gauge, Paragraph, Row, Table},
};
use std::{
    collections::VecDeque,
    env,
    error::Error,
    io,
    time::{Duration, Instant},
};

mod monitor;
use monitor::SystemMonitor;
mod theme;
use theme::{Theme, ThemeKind};

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

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum Overlay {
    None,
    Help,
    Setup,
    Search,
    Filter,
}

fn print_help() {
    println!(
        "🌟 {} v{} - High-performance system monitoring tool",
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
    println!("    Futuristic TUI system monitor for Linux x86_64");
    println!("    - Real-time CPU, memory, network monitoring with charts");
    println!("    - Advanced process management with htop-like features");
    println!("    - Multiple elegant themes (Light, Dark, Stellar, Matrix)");
    println!("    - Lightweight and optimized for ArchLinux");
    println!();
    println!("CONTROLS:");
    println!("    F1-F10           Function keys for all features");
    println!("    ↑/↓ arrows       Navigate process list");
    println!("    q, F10           Quit application");
    println!();
    println!("EXAMPLES:");
    println!("    {}              Start the TUI system monitor", NAME);
    println!("    {} --help       Show this help message", NAME);
    println!();
    println!();
    println!("KEYBOARD SHORTCUTS:");
    println!("    F1  Help         F6  Sort modes     F11/F12 Themes");
    println!("    F2  Setup        F7  Nice decrease  ");
    println!("    F3  Search       F8  Nice increase  ");
    println!("    F4  Filter       F9  Kill process   ");
    println!("    F5  Tree view    F10 Quit           ");
    println!();
    println!("REPOSITORY:");
    println!("    https://github.com/oxyzenQ/lyvoxa");
}

fn print_version() {
    println!("{} {}", NAME, VERSION);
}

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
    tree_view: bool,
    selected: usize,
    status_message: Option<String>,
}

impl App {
    fn new() -> App {
        App {
            monitor: SystemMonitor::new(),
            should_quit: false,
            cpu_history: VecDeque::with_capacity(300),
            memory_history: VecDeque::with_capacity(300),
            net_rx_history: VecDeque::with_capacity(300),
            net_tx_history: VecDeque::with_capacity(300),
            last_update: Instant::now(),
            theme_kind: ThemeKind::Stellar,
            theme: Theme::palette(ThemeKind::Stellar),
            overlay: Overlay::None,
            input_buffer: String::new(),
            filter: String::new(),
            search: String::new(),
            sort_key: SortKey::Cpu,
            tree_view: false,
            selected: 0,
            status_message: None,
        }
    }

    fn cycle_theme(&mut self, next: bool) {
        self.theme_kind = match (self.theme_kind, next) {
            (ThemeKind::Light, true) => ThemeKind::Dark,
            (ThemeKind::Dark, true) => ThemeKind::Stellar,
            (ThemeKind::Stellar, true) => ThemeKind::Matrix,
            (ThemeKind::Matrix, true) => ThemeKind::Light,
            (ThemeKind::Light, false) => ThemeKind::Matrix,
            (ThemeKind::Dark, false) => ThemeKind::Light,
            (ThemeKind::Stellar, false) => ThemeKind::Dark,
            (ThemeKind::Matrix, false) => ThemeKind::Stellar,
        };
        self.theme = Theme::palette(self.theme_kind);
    }

    fn update(&mut self) {
        if self.last_update.elapsed() >= Duration::from_millis(1000) {
            self.monitor.refresh();

            // Update CPU history
            let cpu_usage = self.monitor.get_global_cpu_usage();
            self.cpu_history.push_back(cpu_usage);
            if self.cpu_history.len() > 120 {
                self.cpu_history.pop_front();
            }

            // Update memory history
            let memory_usage = self.monitor.get_memory_usage_percent();
            self.memory_history.push_back(memory_usage);
            if self.memory_history.len() > 120 {
                self.memory_history.pop_front();
            }

            // Update network history (bytes/sec)
            let (rx, tx) = self.monitor.get_network_rates();
            self.net_rx_history.push_back(rx);
            self.net_tx_history.push_back(tx);
            if self.net_rx_history.len() > 120 {
                self.net_rx_history.pop_front();
            }
            if self.net_tx_history.len() > 120 {
                self.net_tx_history.pop_front();
            }

            self.last_update = Instant::now();
        }
    }

    fn handle_key(&mut self, key: KeyEvent) {
        match self.overlay {
            Overlay::Search | Overlay::Filter => {
                match key.code {
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
                }
                return;
            }
            _ => {}
        }

        match key.code {
            KeyCode::Char('q') | KeyCode::F(10) => self.should_quit = true,
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
                self.tree_view = !self.tree_view;
            }
            KeyCode::F(6) => {
                self.sort_key = match self.sort_key {
                    SortKey::Cpu => SortKey::Mem,
                    SortKey::Mem => SortKey::Pid,
                    SortKey::Pid => SortKey::User,
                    SortKey::User => SortKey::Command,
                    SortKey::Command => SortKey::Cpu,
                };
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
                self.cycle_theme(false);
            }
            KeyCode::F(12) => {
                self.cycle_theme(true);
            }
            _ => {}
        }
    }

    fn collect_processes(&self, limit: usize) -> Vec<monitor::ProcessInfo> {
        let mut procs = self.monitor.get_top_processes(200);
        if !self.filter.is_empty() {
            let term = self.filter.to_lowercase();
            procs.retain(|p| {
                p.command.to_lowercase().contains(&term) || p.user.to_lowercase().contains(&term)
            });
        }
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
        if procs.len() > limit {
            procs.truncate(limit);
        }
        procs
    }

    fn selected_pid(&self) -> Option<u32> {
        let list = self.collect_processes(200);
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
    let mut last_tick = Instant::now();
    let tick_rate = Duration::from_millis(250);

    loop {
        terminal
            .draw(|f| ui(f, &app))
            .map_err(|e| io::Error::other(e.to_string()))?;

        let timeout = tick_rate
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));

        if crossterm::event::poll(timeout)?
            && let Event::Key(key) = event::read()?
        {
            app.handle_key(key)
        }

        if last_tick.elapsed() >= tick_rate {
            app.update();
            last_tick = Instant::now();
        }

        if app.should_quit {
            return Ok(());
        }
    }
}

fn ui(f: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints([
            Constraint::Length(3),  // Header
            Constraint::Length(7),  // CPU and Memory gauges
            Constraint::Length(5),  // Per-core gauges
            Constraint::Length(12), // Charts (CPU/Mem/Net)
            Constraint::Min(0),     // Process list
        ])
        .split(f.area());

    // Header
    let header_text = format!(
        "Lyvoxa v{} | Theme: {:?} | Sort: {:?} | Filter: {} | {}",
        VERSION,
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
                .title("Lyvoxa - F1 Help | F10 Quit")
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
    let chart_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(34),
            Constraint::Percentage(33),
            Constraint::Percentage(33),
        ])
        .split(chunks[3]);

    // CPU chart
    if !app.cpu_history.is_empty() {
        let cpu_data: Vec<(f64, f64)> = app
            .cpu_history
            .iter()
            .enumerate()
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

    // Memory chart
    if !app.memory_history.is_empty() {
        let memory_data: Vec<(f64, f64)> = app
            .memory_history
            .iter()
            .enumerate()
            .map(|(i, &mem)| (i as f64, mem))
            .collect();

        let datasets = vec![
            Dataset::default()
                .name("Memory %")
                .marker(symbols::Marker::Dot)
                .style(Style::default().fg(Color::Green))
                .data(&memory_data),
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
    if !app.net_rx_history.is_empty() {
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
        // Determine max for bounds
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

    // Process list
    let processes = app.collect_processes(200);
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
            .title("Processes (F3 Search, F4 Filter, F6 Sort, F7/F8 Nice, F9 Kill)"),
    );
    f.render_widget(process_table, chunks[4]);

    // Overlays
    match app.overlay {
        Overlay::Help => {
            let area = centered_rect(70, 60, f.area());
            let help_text = "F1 Help  F2 Setup  F3 Search  F4 Filter  F5 Tree  F6 Sort  F7 Nice-  F8 Nice+  F9 Kill  F10 Quit\n\nArrows: Navigate selection\nEnter: Confirm in dialogs\nEsc: Close overlays\n\nF11/F12: Cycle themes (extra)\n";
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
            let area = centered_rect(60, 40, f.area());
            let setup_text = "Setup (placeholder)\n- Theme: use F11/F12\n- Sorting: F6\n- Filters: F4\n- Search: F3\n";
            f.render_widget(Clear, area);
            let p = Paragraph::new(setup_text)
                .style(Style::default().fg(app.theme.fg).bg(app.theme.bg))
                .block(
                    Block::default()
                        .borders(Borders::ALL)
                        .title("Setup")
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
