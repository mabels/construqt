
#[derive(Serialize, Debug, Clone, Deserialize)] //, RustcDecodable, RustcEncodable)]
pub struct PkgDesc {
  pub url: String,
  pub name: String,
  pub size: usize,
  pub sum_type: String,
  pub sum: String,
}

#[derive(Serialize, Debug, Clone, Deserialize)] //,RustcDecodable, RustcEncodable)]
pub struct ReqPackageList {
  dist: String,
  arch: String,
  version: String,
  packages: Vec<String>
}
