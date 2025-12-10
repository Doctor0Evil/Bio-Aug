use structopt::StructOpt;
use std::path::PathBuf;
use anyhow::Context;
use serde::{Deserialize};
use std::fs::File;
use std::io::Read;
use glob::glob;

#[derive(StructOpt)]
struct Opt {
    #[structopt(parse(from_os_str))]
    scenario: PathBuf,

    #[structopt(long, parse(from_os_str))]
    policies: Option<PathBuf>,
}

#[derive(Deserialize)]
struct Scenario {
    name: String,
    events: Vec<Event>,
}

#[derive(Deserialize)]
struct Event {
    source: String,
    action: String,
    channel: Option<String>,
}

fn main() -> anyhow::Result<()> {
    let opt = Opt::from_args();
    let mut file = File::open(&opt.scenario).context("open scenario file")?;
    let mut s = String::new(); file.read_to_string(&mut s)?;
    let scenario: Scenario = serde_json::from_str(&s).context("parse scenario")?;

    // Load policy bundles and check for guard strings
    let mut guards = Vec::new();
    if let Some(pol_dir) = opt.policies {
        let pattern = format!("{}/*.yaml", pol_dir.display());
        for entry in glob(&pattern)? {
            let path = entry?;
            let mut p = File::open(&path)?; let mut txt = String::new(); p.read_to_string(&mut txt)?;
            if txt.contains("biomech.no_direct_net_to_actuator") { guards.push("no_direct_net_to_actuator"); }
        }
    }

    // Evaluate scenario events
    let mut pass = true;
    for ev in scenario.events.iter() {
        if ev.source.to_lowercase() == "internet" && ev.action.to_lowercase() == "actuate" {
            if !guards.contains(&"no_direct_net_to_actuator") {
                println!("VIOLATION: internet -> actuate event in scenario '{}' (channel: {:?})", scenario.name, ev.channel);
                pass = false;
            } else {
                println!("Guarded internet->actuate prevented in scenario '{}'", scenario.name);
            }
        }
    }

    if pass { println!("Scenario {}: PASS", scenario.name); std::process::exit(0); }
    else { println!("Scenario {}: FAIL", scenario.name); std::process::exit(2); }
}
