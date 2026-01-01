use std::{fs::write, path::PathBuf};

use image::ImageReader;
use indexmap::IndexMap;
use wfinfo::{
    database::Database,
    ocr::{detect_theme, normalize_string, reward_image_to_reward_names},
    testing::Label,
};

fn main() {
    let mut labels = IndexMap::new();

    for argument in std::env::args().skip(1) {
        let filepath = PathBuf::from(argument);
        let image = ImageReader::open(&filepath).unwrap().decode().unwrap();

        let detections = reward_image_to_reward_names(image.clone(), None);
        println!("{:#?}", detections);

        // 1. Get the Vec out of the Result first
        let detections_vec = detections.expect("OCR failed"); 

        // 2. Now iterate over the strings
        let text: Vec<String> = detections_vec
            .iter()
            .map(|s| normalize_string(s)) // Now 's' is a &String, which works as &str
            .collect();

        let db = Database::load_from_file(None, None, Some(1.0), Some(35.0 / 3.0));
        let items: Vec<_> = text.iter().map(|s| db.find_item(s, None)).collect();
        for item in items.iter() {
            if let Some(item) = item {
                println!("{}: {}\n", item.name, item.platinum);
            } else {
                println!("Unknown item\n");
            }
        }
        let item_names = items
            .iter()
            .map(|item| {
                item.map(|item| item.name.clone())
                    .unwrap_or_else(|| "ERROR".to_string())
            })
            .collect();
        let theme = detect_theme(&image);
        labels.insert(
            filepath
                .file_name()
                .unwrap()
                .to_owned()
                .to_string_lossy()
                .to_string(),
            Label {
                theme: theme.expect("Theme was not loaded correctly"),
                items: item_names,
            },
        );

        println!("{:?}", filepath);

        // let mut buffer = "".to_string();
        // stdin().read_line(&mut buffer).unwrap();
    }

    let labels_json = serde_json::to_string_pretty(&labels).unwrap();
    write("labels.json", labels_json).unwrap();
}
