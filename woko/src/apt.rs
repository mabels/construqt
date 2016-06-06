

extern crate regex;
//extern crate iron;
//extern crate bodyparser;
extern crate time;
extern crate persistent;
extern crate rustc_serialize;
extern crate serde_json;

use regex::Regex;
use std::process::Command;

//use woko::apt;
//use iron::prelude::*;
//use iron::{BeforeMiddleware, AfterMiddleware, typemap};
//use time::precise_time_ns;

//use persistent::Read;
//use iron::status;

//use rustc_serialize::json::{self, ToJson, Json};
//use rustc_serialize::json;

#[derive(Debug, Clone, Deserialize, RustcDecodable, RustcEncodable)]
pub struct PkgDesc {
    pub url: String,
    pub name: String,
    pub size: usize,
    pub sum_type: String,
    pub sum: String,
}

#[derive(Debug, Clone, Deserialize,RustcDecodable, RustcEncodable)]
pub struct ReqPackageList {
    dist: String,
    arch: String,
    version: String,
    packages: Vec<String>
}


pub fn parse(req: &ReqPackageList) -> Result<Vec<PkgDesc>, String> {
    let lxc_name = format!("{}-{}-{}", &req.dist, &req.version, &req.arch);
    let mut fix_lxc_quirk_cmd = Command::new("lxc-info");
    fix_lxc_quirk_cmd.arg("-n");
    fix_lxc_quirk_cmd.arg(&lxc_name);
    let fix_lxc_quirk_ = fix_lxc_quirk_cmd.output();
    if fix_lxc_quirk_.is_err() {
        return Err(format!("failed to execute lxc_info"));
    }
    let fix_lxc_quirk = fix_lxc_quirk_.unwrap();
    if !fix_lxc_quirk.status.success() {
        return Err(format!("failed to execute lxc_info for {} status {}", 
		&lxc_name,
		fix_lxc_quirk.status.code().unwrap()));
    }
    let mut apt_get_cmd = Command::new("lxc-execute");
    apt_get_cmd.arg("-n");
    apt_get_cmd.arg(&lxc_name);
    apt_get_cmd.arg("--");
    apt_get_cmd.arg("apt-get");
    apt_get_cmd.arg("install");
    for pkg in &req.packages {
        //println!("parse:1");
        apt_get_cmd.arg(pkg);
    }
    apt_get_cmd.arg("--print-uris").arg("-qq");
    let apt_get_ = apt_get_cmd.output();
    if apt_get_.is_err() {
        return Err(format!("failed to execute apt-get"));
    }
    let apt_get = apt_get_.unwrap();
    println!(">>>>{} {:?} {:?}", apt_get.status,
			      apt_get.status.success(),
    			      apt_get.status.code());
    if !apt_get.status.success() {
        return Err(format!("failed to execute apt-get status {}", apt_get.status.code().unwrap()));
    }
	
    return parse_from_string(&String::from_utf8_lossy(&apt_get.stdout)
        .as_ref()
        .to_string());
}

pub fn parse_from_string(lines: &String) -> Result<Vec<PkgDesc>, String> {
    let mut ret: Vec<PkgDesc> = Vec::new();
    let re = Regex::new(r"^'((?:[^'\\]|\\.)*)'\s+(\S+)\s+(\d+)\s+(\S+):(\S+)$").unwrap();
    let re_crnl = Regex::new(r"\s*[\n\r]+\s*").unwrap();
    let mut split = re_crnl.split(lines);
    loop {
        match split.next() {
            None => {
                break;
            }
            Some(line) => {
                //println!(">{}", line);
                for cap in re.captures_iter(line) {
                    let pkg_desc = PkgDesc {
                        // url: "url",
                        // name: "name",
                        // size: 4711,
                        // sum_type: "sum_type",
                        // sum: "sum",
                        url: cap.at(1).unwrap().to_string(),
                        name: cap.at(2).unwrap().to_string(),
                        size: cap.at(3).unwrap().parse::<usize>().unwrap(),
                        sum_type: cap.at(4).unwrap().to_string(),
                        sum: cap.at(5).unwrap().to_string(),
                    };
                    ret.push(pkg_desc);
                }
            }
        }
    }
    return Ok(ret);
}
