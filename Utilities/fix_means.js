/**

node fix_means <firebase_expt>.json 

-> <firebase_expt>_updated_means.json

e.g. 

node fix_means bartenderdata-DMY-export.json

recalculates the group means for each measure for each collection time/date based on subject data,
then writes out an updated json file

    mean dates may be different for each measure, because not all measures have the same collection dates
    e.g. body weight may be a few minutes off from bottle weights

*/

const fs = require('fs');
const csv_parse = require('csv-parse/lib/sync');

const json_file = process.argv[2];

var expt = JSON.parse(fs.readFileSync(json_file, 'utf8'));


/**********************************************************************/
// from chatGPT4 


class RunningStats {
    constructor() {
        this.n = 0; // Number of data points
        this.mean = 0; // Current mean
        this.M2 = 0; // Sum of squares of differences from the mean
    }

    push(value) {
        this.n += 1;
        const delta = value - this.mean;
        this.mean += delta / this.n;
        const delta2 = value - this.mean;
        this.M2 += delta * delta2;
    }

    getMean() {
        return this.mean;
    }

    getVariance() {
        if (this.n < 2) {
            return 0; // Need at least two data points for variance
        }
        return this.M2 / (this.n - 1); // sample variance, not population variance
    }

    getStandardDeviation() {
        return Math.sqrt(this.getVariance());
    }

    getSEM() {
        return this.getStandardDeviation() / Math.sqrt(this.n);
    }

    getN() {
        return this.n;
    }
}

/**********************************************************************/



// for  each measure, for each group, iterate over all the dates 

const groups = Object.keys(expt.groups);
const measures = Object.keys(expt.measures);
const subjects = Object.keys(expt.subjects);


var group_means = {};

measures.forEach(function(m) {

    // get dates separately for each measure, because not all measures have the same collection dates
    // e.g. body weight a few minutes off from bottle weights

    var measure_dates = new Set();


    subjects.forEach(function(s) {

        const dates = Object.keys(expt.subjects[s].data[m]);

        dates.forEach(d => measure_dates.add(d));

    }); // next subject
    
 //   console.log("\n\n",m);
 //   console.log(measure_dates);

    // set up group means data structure
    groups.forEach(function(g) {

        if (typeof group_means[g]  == "undefined") {
            group_means[g] = {};
        }
        if (typeof group_means[g][m]  == "undefined") {
            group_means[g][m] = {};
        }

        measure_dates.forEach(function(d) {

            const stats = new RunningStats();

            group_means[g][m][d] = {
                "mean": -32000,
                "n": 0,
                "sem": 0
            };

            subjects.forEach(function(s) {

                if (g == expt["subjects"][s]["group"]) {

                    let datum = expt["subjects"][s]["data"][m][d];

                    // console.log(s," ",m," ",d," ",datum);

                    if (typeof datum != "undefined" && null != datum && -32000 != datum) {
                        stats.push(datum);
                        //  console.log(g," ",s," ",m," ",d," ",datum);
                    }

                }

            }); // next subject

            group_means[g][m][d].mean = stats.getMean();
            group_means[g][m][d].n = stats.getN();
            group_means[g][m][d].sem = stats.getSEM();

            if (0 == group_means[g][m][d].n) {
                group_means[g][m][d].mean = -32000;
                group_means[g][m][d].sem = 0;
            }

        }); // next date


    }); // next group

}); // next measure

// console.log(JSON.stringify(group_means, null, "   "));

// swap in newly recalculated group means
expt.group_means = group_means;


const updated_json = json_file.replace(".json","_updated_means.json");

fs.writeFileSync(updated_json,JSON.stringify(expt,null,"\t"));
