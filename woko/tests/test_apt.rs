


extern crate woko;

// use std::io::prelude::*;

#[cfg(test)]
mod tests {
    use std::fs::File;
    use std::io::Read;
    use std::path::Path;
    //use std::collections::HashMap;
    use woko::apt;

    fn read() -> String {
        let mut f = File::open(Path::new("tests/apt.out")).unwrap();
        let mut s = String::new();
        f.read_to_string(&mut s).ok();
        return s;
    }

    #[test]
    fn test_woko_apt() {
        let apts = apt::parse_from_string(&read()).unwrap();
        let l122 = apts.get(121).unwrap();
        assert_eq!(132, apts.len());
        assert_eq!("http://archive.ubuntu.com/ubuntu/pool/main/r/rename/rename_0.20-4_all.deb", l122.url);
        assert_eq!("rename_0.20-4_all.deb", l122.name);
        assert_eq!(12010, l122.size);
        assert_eq!("MD5Sum", l122.sum_type);
        assert_eq!("6cf1938ef51145a469ccef181a9304ce", l122.sum);
    }

}
