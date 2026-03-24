use wolfram_library_link::export;
use wolfram_expr::{Expr, Symbol};
use std::fs::{self, File};
use std::io::{copy};
use std::path::Path;
use zip::write::FileOptions;
use zip::{ZipWriter, ZipArchive, CompressionMethod};
use walkdir::WalkDir;
use serde::Deserialize;

#[derive(Deserialize, Default)]
struct ZipOptions {
    #[serde(rename = "ZipMethod")]
    compression_method: Option<String>,
    #[serde(rename = "ZipLevel")]
    compression_level: Option<i32>,
}

#[export(wstp)]
fn zip_file(args: Vec<Expr>) -> Expr {
    if args.len() < 2 {
        return Expr::string("Error: expected at least 2 arguments (source, dest)");
    }
    
    let source = match args[0].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: first argument must be a string"),
    };
    
    let dest = match args[1].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: second argument must be a string"),
    };

    let options_json = if args.len() >= 3 {
        args[2].try_as_str()
    } else {
        None
    };

    match zip_internal(source, dest, options_json) {
        Ok(_) => Expr::string(dest),
        Err(e) => Expr::string(&format!("Error: {}", e)),
    }
}

#[export(wstp)]
fn unzip_file(args: Vec<Expr>) -> Expr {
    if args.len() != 2 {
        return Expr::string("Error: expected 2 arguments (source, dest)");
    }
    
    let source = match args[0].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: first argument must be a string"),
    };
    
    let dest = match args[1].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: second argument must be a string"),
    };

    match unzip_internal(source, dest) {
        Ok(_) => Expr::string(dest),
        Err(e) => Expr::string(&format!("Error: {}", e)),
    }
}

#[export(wstp)]
fn zip_info(args: Vec<Expr>) -> Expr {
    if args.len() != 1 {
        return Expr::string("Error: expected 1 argument (source)");
    }
    
    let source = match args[0].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: argument must be a string"),
    };

    match zip_info_internal(source) {
        Ok(info) => info,
        Err(e) => Expr::string(&format!("Error: {}", e)),
    }
}

#[export(wstp)]
fn zip_extract_file(args: Vec<Expr>) -> Expr {
    if args.len() != 3 {
        return Expr::string("Error: expected 3 arguments (source, file_name, dest)");
    }
    
    let source = match args[0].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: first argument must be a string (source)"),
    };
    
    let file_name = match args[1].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: second argument must be a string (file_name)"),
    };

    let dest = match args[2].try_as_str() {
        Some(s) => s,
        None => return Expr::string("Error: third argument must be a string (dest)"),
    };

    match zip_extract_internal(source, file_name, dest) {
        Ok(path) => Expr::string(&path),
        Err(e) => Expr::string(&format!("Error: {}", e)),
    }
}

fn get_compression_method(method: &str) -> Option<CompressionMethod> {
    match method {
        "Deflate" => Some(CompressionMethod::Deflated),
        "Bzip2" => Some(CompressionMethod::Bzip2),
        "ZStandard" => Some(CompressionMethod::Zstd),
        "None" => Some(CompressionMethod::Stored),
        _ => None,
    }
}

fn zip_internal(source: &str, dest: &str, options_json: Option<&str>) -> Result<(), String> {
    let path = Path::new(source);
    let zip_file = File::create(dest).map_err(|e| e.to_string())?;
    let mut zip = ZipWriter::new(zip_file);
    
    let mut method = CompressionMethod::Deflated;
    let mut compression_level = None;
    
    if let Some(json) = options_json {
        if let Ok(opts) = serde_json::from_str::<ZipOptions>(json) {
            if let Some(m_str) = opts.compression_method {
                if let Some(m) = get_compression_method(&m_str) {
                    method = m;
                }
            }
            compression_level = opts.compression_level;
        }
    }

    let mut options = FileOptions::default()
        .compression_method(method)
        .unix_permissions(0o755);
    
    if let Some(level) = compression_level {
        options = options.compression_level(Some(level));
    }

    if path.is_file() {
        zip.start_file(path.file_name().unwrap().to_str().unwrap(), options)
            .map_err(|e| e.to_string())?;
        let mut f = File::open(path).map_err(|e| e.to_string())?;
        copy(&mut f, &mut zip).map_err(|e| e.to_string())?;
    } else if path.is_dir() {
        for entry in WalkDir::new(path).into_iter().filter_map(|e| e.ok()) {
            let entry_path = entry.path();
            let name = entry_path.strip_prefix(path).map_err(|e| e.to_string())?;

            if entry_path.is_file() {
                zip.start_file(name.to_str().unwrap(), options)
                    .map_err(|e| e.to_string())?;
                let mut f = File::open(entry_path).map_err(|e| e.to_string())?;
                copy(&mut f, &mut zip).map_err(|e| e.to_string())?;
            } else if !name.as_os_str().is_empty() {
                zip.add_directory(name.to_str().unwrap(), options)
                    .map_err(|e| e.to_string())?;
            }
        }
    } else {
        return Err("Source path does not exist".to_string());
    }

    zip.finish().map_err(|e| e.to_string())?;
    Ok(())
}

fn unzip_internal(source: &str, dest: &str) -> Result<(), String> {
    let fname = Path::new(source);
    let file = File::open(&fname).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;

    for i in 0..archive.len() {
        let mut file = archive.by_index(i).map_err(|e| e.to_string())?;
        let outpath = match file.enclosed_name() {
            Some(path) => Path::new(dest).join(path),
            None => continue,
        };

        if file.name().ends_with('/') {
            fs::create_dir_all(&outpath).map_err(|e| e.to_string())?;
        } else {
            if let Some(p) = outpath.parent() {
                if !p.exists() {
                    fs::create_dir_all(&p).map_err(|e| e.to_string())?;
                }
            }
            let mut outfile = File::create(&outpath).map_err(|e| e.to_string())?;
            copy(&mut file, &mut outfile).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

fn zip_info_internal(source: &str) -> Result<Expr, String> {
    let file = File::open(source).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;
    let mut list = Vec::new();

    for i in 0..archive.len() {
        let file = archive.by_index(i).map_err(|e| e.to_string())?;
        let mut rules = Vec::new();
        rules.push(Expr::rule(Expr::string("FileName"), Expr::string(file.name())));
        rules.push(Expr::rule(Expr::string("Size"), Expr::from(file.size() as i64)));
        rules.push(Expr::rule(Expr::string("CompressedSize"), Expr::from(file.compressed_size() as i64)));
        rules.push(Expr::rule(Expr::string("CompressionMethod"), Expr::string(&file.compression().to_string())));
        rules.push(Expr::rule(Expr::string("CRC32"), Expr::from(file.crc32() as i64)));
        
        list.push(Expr::normal(Symbol::new("System`Association"), rules));
    }
    Ok(Expr::list(list))
}

fn zip_extract_internal(source: &str, file_name: &str, dest: &str) -> Result<String, String> {
    let file = File::open(source).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;
    let mut file = archive.by_name(file_name).map_err(|e| e.to_string())?;
    
    let file_path = Path::new(file.name());
    let outpath = Path::new(dest).join(file_path);
    if let Some(p) = outpath.parent() {
        fs::create_dir_all(p).map_err(|e| e.to_string())?;
    }
    
    let mut outfile = File::create(&outpath).map_err(|e| e.to_string())?;
    copy(&mut file, &mut outfile).map_err(|e| e.to_string())?;
    
    Ok(outpath.to_str().unwrap().to_string())
}
