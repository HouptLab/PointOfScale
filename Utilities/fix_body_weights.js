/**

node fix_body_weights <firebase_expt>.json <body_weights_csv> [ALL]

-> <firebase_expt>_updated.json

e.g. 

node fix_body_weights bartenderdata-DMY-export.json DMY_restriction.csv

node fix_body_weights bartenderdata-DMY-export.json DMY_postop.csv

if last argument is "ALL", then all weights are replaced with those in csv

take body weights in csv file, and patch the json with the (presumanly) missing body weights; recalculate group averages


*/

const fs = require('fs');
const csv_parse = require('csv-parse/lib/sync');
//var csv_stringify = require('csv-stringify/lib/sync');

const json_file = process.argv[2];
const csv_file = process.argv[3];

let replace_all = false;

if ( process.argv.length == 5) {
    if ("ALL" == process.argv[4]) {
        replace_all = true;
    }
}



var expt = JSON.parse(fs.readFileSync(json_file, 'utf8'));

// read in csv file, where:
// first column is animal ids, with header "Subject"
// subsequent columns are body weights (header is date and time of weighing)
// note date should have leading zeros for month and day, i.e. 2024-09-01

const text_csv = fs.readFileSync(csv_file,'utf8');

const weights = csv_parse(text_csv, {'columns':true, 'objname': "Subject"});

// console.log(JSON.stringify(weights,null,"   "));

const rats = Object.keys(weights);

const numRats = rats.length;


// make sure body weight is a measure

if ("undefined" == typeof expt["measures"]["Body Weight"]) {
        expt["measures"]["Body Weight"] = "Body Weight";
}

// update the body weights

    Object.keys(weights).forEach ( function (r) {
    
        console.log(r);
      if ("undefined" == typeof expt["subjects"][r]["data"]["Body Weight"]) {
        expt["subjects"][r]["data"]["Body Weight"] = {};
      }
      if (replace_all) {
        expt["subjects"][r]["data"]["Body Weight"] = {};
      }
      
      Object.keys(weights[r]).forEach ( function (d) {

        if ("Subject" != d) {
        
            if ("--" == weights[r][d]) {
                expt["subjects"][r]["data"]["Body Weight"][d] = -32000;
            }else {
                let raw_weight = parseInt(weights[r][d],10);
                if (typeof raw_weight == "undefined" || null == raw_weight) {
                    expt["subjects"][r]["data"]["Body Weight"][d] = -32000;
                }
                else {
                    expt["subjects"][r]["data"]["Body Weight"][d] = raw_weight;
                }
            }
            
            console.log("    ", d,"    ",weights[r][d], " --> ", expt["subjects"][r]["data"]["Body Weight"][d]);
        }
            
    }); // weights for one rat
    
    const sortedWeights = {};

Object.keys( expt["subjects"][r]["data"]["Body Weight"])
  .sort() // Sort the keys alphabetically
  .forEach(key => {
    sortedWeights[key] =  expt["subjects"][r]["data"]["Body Weight"][key];
  });
  
    expt["subjects"][r]["data"]["Body Weight"] = sortedWeights;

}); // next rat


// console.log(JSON.stringify(expt,null,"\t"));

const updated_json = json_file.replace(".json","_updated.json");

fs.writeFileSync(updated_json,JSON.stringify(expt,null,"\t"));

