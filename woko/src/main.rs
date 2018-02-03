//#![feature(custom_derive, plugin)]
//#![plugin(serde_macros)]


extern crate regex;
// extern crate iron;
//extern crate bodyparser;
//extern crate time;
//extern crate persistent;
//extern crate rustc_serialize;
extern crate serde_json;
// #[macro_use]
extern crate hyper;
//extern crate hyper_tls;
extern crate env_logger;
extern crate tokio_core;
extern crate tokio_proto;
extern crate tokio_rustls;
extern crate rustls;
extern crate futures;
extern crate futures_cpupool;

#[macro_use] extern crate log;

use futures::Stream;
use futures::Future;

//#[macro_use] extern crate mime;

pub mod apt;


//use woko::apt;
// use std::io::Read;
// use std::io::Write;
//use iron::{BeforeMiddleware, AfterMiddleware, typemap};
//use time::precise_time_ns;

//use persistent::Read;
// use iron::prelude::*;
// use iron::status;
// use iron::headers;

// use hyper::net::Openssl;
// use std::io;
use rustls::internal::pemfile;
use rustls::NoClientAuth;
//use tokio_rustls::proto;
//use tokio_rustls::proto;
use hyper::{Post, StatusCode};
use hyper::server::{Http, Service, Request, Response};
use hyper::header::ContentLength;
// use hyper::status::StatusCode;
use hyper::header::ContentType;
// use hyper::mime::{Mime, TopLevel, SubLevel};
// use hyper::mime::*;
//
// use futures::future::FutureResult;

// use futures_cpupool::CpuPool;

//use rustc_serialize::json::{self};
//use rustc_serialize::json;

include!(concat!(env!("OUT_DIR"), "/serde_types.rs"));


static INDEX: &'static [u8] = b"Try POST /";
// static BAD_REQUEST: &'static [u8] = b"Missing field";

struct Woko {
    // pool: futures_cpupool::CpuPool
}

impl Service for Woko {
    type Request = Request;
    type Response = Response;
    type Error = hyper::Error;
    // type Future = Box<Future<Response, hyper::Error>>
    type Future = futures::BoxFuture<Response, hyper::Error>;
    //type Future = Self::Future;

    // FutureResult<Response, hyper::Error>;

    fn call(&self, req: Request) -> Self::Future {
        let (method, uri, _version, headers, body) = req.deconstruct();
        match (method, uri.path()) {
            (Post, _) => {
                let mut res = Response::new();
                                let vec;
                                if let Some(len) = headers.get::<ContentLength>() {
                                    vec = Vec::with_capacity(**len as usize);
                                    res.headers_mut().set(len.clone());
                                } else {
                                    vec = vec![];
                                }
                                Box::new(body.fold(vec, |mut acc, chunk| {
                                    acc.extend_from_slice(chunk.as_ref());
                                    Ok::<_, hyper::Error>(acc)
                                }).and_then(move |value| {
                                    debug!("value: {:?}", &value);
                                    match serde_json::from_slice::<apt::ReqPackageList>(&value) {
                                        Ok(plist) => {
                                            match apt::parse(&plist) {
                                                Ok(apt) => {
                                                    let jsbody = serde_json::to_string(&apt).unwrap();
                                                    // let body = jsbody.as_bytes();
                                                    Ok(res.with_header(ContentType::json())
                                                        // .with_header(ContentLength(body.len() as u64))
                                                        .with_body(jsbody))
                                                }
                                                Err(err) => {
                                                    println!("apt-parse: {}", err);
                                                    Ok(res.with_status(StatusCode::BadRequest)
                                                        .with_header(ContentLength(err.len() as u64))
                                                        .with_body(err))
                                                }
                                            }
                                        },
                                        _ => {
                                            Ok(res.with_status(StatusCode::BadRequest)
                                                .with_body(value))
                                        }
                                    }
                                })) //.boxed()                // self.pool.spawn_fn(|| {
                //     req.body().concat2().map(|b| {
                //         }
                //     })
                // })
            }
            (_, _) => {
                Box::new(futures::future::ok(Response::new()
                    .with_status(StatusCode::BadRequest)
                    .with_body(INDEX)))
            }
        }
        // futures::futu
        //
        //
        //
        // futures::future::ok(match (req.method(), req.path()) {
        //     (&Post, "/") => {
        //     let mut res = Response::new();
        //     Box::new(req.body()
        //                  .concat2()
        //                  .map(|b| {
        //         // let json: serde_json::Value =
        //         if let Ok(plist) = serde_json::from_slice::<apt::ReqPackageList>(b.as_ref()) {
        //             // let mut res = Response::new();
        //             match apt::parse(&plist) {
        //                 Ok(apt) => {
        //                     let jsbody = serde_json::to_string(&apt).unwrap();
        //                     let body = jsbody.as_bytes();
        //                     res.with_header(ContentType::json())
        //                         .with_header(ContentLength(body.len() as u64))
        //                         .with_body(body);
        //                 }
        //                 Err(err) => {
        //                     println!("apt-parse: {}", err);
        //                     res.with_status(StatusCode::BadRequest)
        //                         .with_header(ContentLength(err.len() as u64))
        //                         .with_body(err);
        //                 }
        //             }
        //             return ();
        //         } else {
        //             res.with_status(StatusCode::BadRequest)
        //                 .with_header(ContentLength(BAD_REQUEST.len() as u64))
        //                 .with_body(BAD_REQUEST);
        //         };
        //     }));
        //     // Box::new(futures::future::ok(res))
        //     res
        // }
        //                         (_, _) => {
        //                             Response::new()
        //                                 .with_header(ContentLength(INDEX.len() as u64))
        //                                 .with_body(INDEX)
        //                         }
        //                     })
    }
}


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
//       let mut resp = Response::with((status::Ok,
//           serde_json::to_string(&result.unwrap()).unwrap()));
//       resp.headers.set(headers::ContentType::json());
//       return Ok(resp);
//     }
//     // Ok(None) => return Ok(Response::with((status::ServiceUnavailable, "No Json found"))),
//     Err(err) => return Ok(Response::with((status::ServiceUnavailable,
//               format!("Internal Error:{}", err)))),
//       //            _ => return Ok(Response::with((status::ServiceUnavailable, "unknown case")))
//   }
// }

/*
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
   res.with_status(StatusCode::BadRequest);
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
ContentType(mime!("application/json"))
);
//   res.headers.set(headers::ContentType::json());
res.start().unwrap().write_all(serde_json::to_string(&apt).unwrap().as_bytes()).unwrap();
},
Err(err) => {
println!("apt-parse: {}", err);
res.with_status(StatusCode::MethodNotAllowed);
}
}
},
Err(err) => {
println!("json-parse: {}", err);
res.with_status(StatusCode::MethodNotAllowed);
}
}
},
Err(err) => {
println!("utf8-parse: {}", err);
res.with_status(StatusCode::MethodNotAllowed);
}

}
},
_ => res.with_status(StatusCode::MethodNotAllowed);
}
}
*/


// const MAX_BODY_LENGTH: usize = 1024 * 1024 * 1;

fn load_certs(filename: String) -> Vec<rustls::Certificate> {
    let certfile = std::fs::File::open(filename).expect("cannot open certificate file");
    let mut reader = std::io::BufReader::new(certfile);
    pemfile::certs(&mut reader).unwrap()
}

fn load_private_key(filename: String) -> rustls::PrivateKey {
    let keyfile = std::fs::File::open(filename).expect("cannot open private key file");
    let mut reader = std::io::BufReader::new(keyfile);
    let keys = pemfile::rsa_private_keys(&mut reader).unwrap();
    assert!(keys.len() == 1);
    keys[0].clone()
}


fn main() {
    env_logger::init();
    let key = std::env::args().nth(1);
    let cert = std::env::args().nth(2);
    if key.is_some() && cert.is_some() {
        let key_file = key.unwrap();
        let key = load_private_key(key_file);
        let cert_file = cert.unwrap();
        let certs = load_certs(cert_file);
        let mut cfg = rustls::ServerConfig::new(NoClientAuth::new());
        cfg.set_single_cert(certs, key);
        let tls = tokio_rustls::proto::Server::new(Http::new(), std::sync::Arc::new(cfg));

        let addr = "0.0.0.0:8443".parse().unwrap();
        println!("Starting to serve on https://{}.", addr);
        let tcp = tokio_proto::TcpServer::new(tls, addr);
        tcp.serve(|| Ok(Woko { /* pool: CpuPool::new_num_cpus() */ }));
    } else {
        // let tls = tokio_rustls::proto::Server::new(Http::new());
        let addr = "0.0.0.0:8080".parse().unwrap();
        println!("Starting to serve on http://{}.", addr);
        let tcp = tokio_proto::TcpServer::new(Http::new(), addr);
        tcp.serve(|| Ok(Woko { /* pool:  CpuPool::new_num_cpus() */ }));
    }
    //let mut chain = Chain::new(apt_process);
    //chain.link_before(Read::<bodyparser::MaxBodyLength>::one(MAX_BODY_LENGTH));
    //chain.link_before(ResponseTime);
    //chain.link_after(ResponseTime);
    //Iron::new(chain).https("0.0.0.0:7878").unwrap();
}
