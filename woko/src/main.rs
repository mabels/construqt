//#![feature(custom_derive, plugin)]
//#![plugin(serde_macros)]


extern crate regex;
// extern crate iron;
//extern crate bodyparser;
//extern crate time;
//extern crate persistent;
//extern crate rustc_serialize;
extern crate serde_json;
extern crate hyper;

pub mod apt;


//use woko::apt;
use std::io::Read;
use std::io::Write;
//use iron::{BeforeMiddleware, AfterMiddleware, typemap};
//use time::precise_time_ns;

//use persistent::Read;
// use iron::prelude::*;
// use iron::status;
// use iron::headers;

use hyper::net::Openssl;
// use std::io;
use hyper::server::{Server, Request, Response};
use hyper::status::StatusCode;
use hyper::header::{ContentType};
use hyper::mime::{Mime, TopLevel, SubLevel};


//use rustc_serialize::json::{self};
//use rustc_serialize::json;

include!(concat!(env!("OUT_DIR"), "/serde_types.rs"));

// fn apt_process(req: &mut Request) -> IronResult<Response> {
//
//   //println!(">-<");
//   //let payload = req.get::<bodyparser::Struct<apt::ReqPackageList>>();
//   let mut req_buf =  String::new();
//   match req.body.read_to_string(&mut req_buf) {
//     Ok(_) => {},
//     Err(err) => return Ok(Response::with((status::ServiceUnavailable,
//               format!("Internal Error:{}", err))))
//   }
//   let payload = serde_json::from_str::<apt::ReqPackageList>(&req_buf);
//   //let payload = Some(None);
//
//   //println!(">+<");
//   match payload {
//     Ok(plist) => {
//       //println!(">0<");
//       let result = apt::parse(&plist);
//       if result.is_err() {
//         return Ok(Response::with((status::ServiceUnavailable,
//                 format!("parse error {}", result.err().unwrap()))));
//       }
//       let mut resp = Response::with((status::Ok, serde_json::to_string(&result.unwrap()).unwrap()));
//       resp.headers.set(headers::ContentType::json());
//       return Ok(resp);
//     }
//     // Ok(None) => return Ok(Response::with((status::ServiceUnavailable, "No Json found"))),
//     Err(err) => return Ok(Response::with((status::ServiceUnavailable,
//               format!("Internal Error:{}", err)))),
//       //            _ => return Ok(Response::with((status::ServiceUnavailable, "unknown case")))
//   }
// }

fn hyper_apt_process(req: Request, mut res: Response) {
  match req.method {
    hyper::Post => {
      let mut max = 0;
      let mut req_vec : Vec<u8> = Vec::new();
      for c in req.bytes() {
        req_vec.push(c.unwrap());
        max += 1;
        if max >= 8192 {
          println!("to long");
          *res.status_mut() = StatusCode::BadRequest;
          return;
        }
      }
      match String::from_utf8(req_vec) {
        Ok(req_buf) => {
          match serde_json::from_str::<apt::ReqPackageList>(&req_buf) {
            Ok(plist) => {
              match apt::parse(&plist) {
                Ok(apt) => {
                  //   let mut resp = Response::with((status::Ok, serde_json::to_string(&result.unwrap()).unwrap()));
                  res.headers_mut().set(
                      ContentType(Mime(TopLevel::Application, SubLevel::Json, vec![]))
                      );
                  //   res.headers.set(headers::ContentType::json());
                  res.start().unwrap().write_all(serde_json::to_string(&apt).unwrap().as_bytes()).unwrap();
                },
                  Err(err) => {
                    println!("apt-parse: {}", err);
                    *res.status_mut() = StatusCode::MethodNotAllowed
                  }
              }
            },
              Err(err) => {
                println!("json-parse: {}", err);
                *res.status_mut() = StatusCode::MethodNotAllowed
              }
          }
        },
          Err(err) => {
            println!("utf8-parse: {}", err);
            *res.status_mut() = StatusCode::MethodNotAllowed
          }

      }
    },
      _ => *res.status_mut() = StatusCode::MethodNotAllowed
  }
}


// const MAX_BODY_LENGTH: usize = 1024 * 1024 * 1;

fn main() {
  let key = std::env::args().nth(1);
  let cert = std::env::args().nth(2);
  if key.is_some() && cert.is_some() {
    let key_file = key.unwrap();
    let cert_file = cert.unwrap();
    println!("key={} cert={}", &key_file, &cert_file);
    let ssl = Openssl::with_cert_and_key(&cert_file, &key_file).unwrap();
    Server::https("0.0.0.0:8443", ssl).unwrap().handle(hyper_apt_process).unwrap();
  } else {
    Server::http("0.0.0.0:8080").unwrap().handle(hyper_apt_process).unwrap();
  }
  //let mut chain = Chain::new(apt_process);
  //chain.link_before(Read::<bodyparser::MaxBodyLength>::one(MAX_BODY_LENGTH));
  //chain.link_before(ResponseTime);
  //chain.link_after(ResponseTime);
  //Iron::new(chain).https("0.0.0.0:7878").unwrap();
}
