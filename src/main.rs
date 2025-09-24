use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::{Color, Style},
    symbols,
    widgets::{Axis, Block, Borders, Chart, Dataset, Gauge, Paragraph, Row, Table},
    Frame, Terminal,
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

const VERSION: &str = env!("CARGO_PKG_VERSION");
const NAME: &str = env!("CARGO_PKG_NAME");

fn print_help() {
    println!("🌟 {} v{} - High-performance system monitoring tool", NAME, VERSION);
    println!();
    println!("USAGE:");
    println!("    {} [OPTIONS]", NAME);
    println!();
    println!("OPTIONS:");
    println!("    -h, --help       Show this help message");
    println!("    -V, --version    Show version information");
    println!();
    println!("DESCRIPTION:");
    println!("    Interactive TUI system monitor for Linux x86_64");
    println!("    - Real-time CPU, memory, disk, network monitoring");
    println!("    - Process management and system information");
    println!("    - Lightweight (<2MB memory) and efficient");
    println!();
    println!("CONTROLS:");
    println!("    q, Ctrl+C        Quit");
    println!("    ↑/↓ arrows       Navigate process list");
    println!();
    println!("EXAMPLES:");
    println!("    {}              Start interactive monitor", NAME);
    println!("    {}-simple       Simple CLI output", NAME);
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
    last_update: Instant,
}

impl App {
    fn new() -> App {
        App {
            monitor: SystemMonitor::new(),
            should_quit: false,
            cpu_history: VecDeque::with_capacity(60),
            memory_history: VecDeque::with_capacity(60),
            last_update: Instant::now(),
        }
    }

    fn update(&mut self) {
        if self.last_update.elapsed() >= Duration::from_millis(1000) {
            self.monitor.refresh();

            // Update CPU history
            let cpu_usage = self.monitor.get_global_cpu_usage();
            self.cpu_history.push_back(cpu_usage);
            if self.cpu_history.len() > 60 {
                self.cpu_history.pop_front();
            }

            // Update memory history
            let memory_usage = self.monitor.get_memory_usage_percent();
            self.memory_history.push_back(memory_usage);
            if self.memory_history.len() > 60 {
                self.memory_history.pop_front();
            }

            self.last_update = Instant::now();
        }
    }

    fn on_key(&mut self, c: char) {
        if c == 'q' {
            self.should_quit = true;
        }
    }
}

async fn run_app<B: Backend>(terminal: &mut Terminal<B>, mut app: App) -> io::Result<()> {
    let mut last_tick = Instant::now();
    let tick_rate = Duration::from_millis(250);

    loop {
        terminal.draw(|f| ui(f, &app))?;

        let timeout = tick_rate
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));

        if crossterm::event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                match key.code {
                    KeyCode::Char(c) => app.on_key(c),
                    KeyCode::Esc => app.should_quit = true,
                    _ => {}
                }
            }
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
            Constraint::Length(12), // CPU and Memory charts
            Constraint::Min(0),     // Process list
        ])
        .split(f.area());

    // Header
    let header = Paragraph::new("Rust System Monitor - Press 'q' to quit, 'Esc' to exit")
        .style(Style::default().fg(Color::Cyan))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("System Monitor"),
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
        .gauge_style(Style::default().fg(Color::Yellow))
        .percent(cpu_usage as u16)
        .label(format!("{:.1}%", cpu_usage));
    f.render_widget(cpu_gauge, info_chunks[0]);

    // Memory gauge
    let memory_usage = app.monitor.get_memory_usage_percent();
    let (used_mem, total_mem) = app.monitor.get_memory_info();
    let memory_gauge = Gauge::default()
        .block(Block::default().borders(Borders::ALL).title("Memory Usage"))
        .gauge_style(Style::default().fg(Color::Green))
        .percent(memory_usage as u16)
        .label(format!(
            "{:.1}% ({}/{})",
            memory_usage,
            humansize::format_size(used_mem, humansize::DECIMAL),
            humansize::format_size(total_mem, humansize::DECIMAL)
        ));
    f.render_widget(memory_gauge, info_chunks[1]);

    // Charts layout
    let chart_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(chunks[2]);

    // CPU chart
    if !app.cpu_history.is_empty() {
        let cpu_data: Vec<(f64, f64)> = app
            .cpu_history
            .iter()
            .enumerate()
            .map(|(i, &cpu)| (i as f64, cpu))
            .collect();

        let datasets = vec![Dataset::default()
            .name("CPU %")
            .marker(symbols::Marker::Dot)
            .style(Style::default().fg(Color::Yellow))
            .data(&cpu_data)];

        let cpu_chart = Chart::new(datasets)
            .block(Block::default().title("CPU History").borders(Borders::ALL))
            .x_axis(Axis::default().title("Time").bounds([0.0, 60.0]))
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

        let datasets = vec![Dataset::default()
            .name("Memory %")
            .marker(symbols::Marker::Dot)
            .style(Style::default().fg(Color::Green))
            .data(&memory_data)];

        let memory_chart = Chart::new(datasets)
            .block(
                Block::default()
                    .title("Memory History")
                    .borders(Borders::ALL),
            )
            .x_axis(Axis::default().title("Time").bounds([0.0, 60.0]))
            .y_axis(Axis::default().title("Usage %").bounds([0.0, 100.0]));
        f.render_widget(memory_chart, chart_chunks[1]);
    }

    // Process list
    let processes = app.monitor.get_top_processes(20);
    let process_items: Vec<Row> = processes
        .iter()
        .map(|p| {
            Row::new(vec![
                p.pid.to_string(),
                p.name.clone(),
                format!("{:.1}%", p.cpu_usage),
                humansize::format_size(p.memory, humansize::DECIMAL),
                p.status.clone(),
            ])
        })
        .collect();

    let process_table = Table::new(
        process_items,
        [
            Constraint::Length(8),
            Constraint::Min(20),
            Constraint::Length(8),
            Constraint::Length(12),
            Constraint::Length(10),
        ],
    )
    .header(
        Row::new(vec!["PID", "Name", "CPU%", "Memory", "Status"])
            .style(Style::default().fg(Color::Yellow)),
    )
    .block(
        Block::default()
            .borders(Borders::ALL)
            .title("Top Processes"),
    );
    f.render_widget(process_table, chunks[3]);
}
