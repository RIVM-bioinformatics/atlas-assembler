import requests, json, os, glob, argparse, pathlib, sys, shutil

def rest_call(url):
    response = requests.get(url, verify=False)
    try:
        return_data = response.json()
    except:
        raise Exception("url '{}' gives no json data".format(url))
    return return_data, response.status_code

def main(args):
    server = args.server
    RUNID = "irods_input_minion__sample_id"

    if RUNID not in os.environ:
        raise EnvironmentError("Env var '{}' not found.".format(RUNID))

    barcoderdir = os.path.abspath(args.inputdir)

    if not os.path.exists(barcoderdir):
        raise FileNotFoundError("Input dir '{}' not found.".format(barcoderdir))

    if not os.path.exists(args.outputdir):
        raise FileNotFoundError("Output dir '{}' not found.".format(args.outputdir))

    print("Barcodes dir", barcoderdir)

    request = server + "/ngsruns/api/v2/runs/id/" + os.environ[RUNID]
    print(request)
    runinfo, response = rest_call(request)
    if not runinfo or response != 200:
        raise BaseException(
            "webserver '{}' error.".format(response) + " from " + request
        )
    print("runinfo:", runinfo)
    f = open(os.path.join(args.outputdir, "metadata.yml"), "a")
    f.write("user::runinfo::name: " + runinfo["name"] + "\n")
    f.write("user::runinfo::id: " + str(runinfo["id"]) + "\n")
    f.close()

    request = server + "/ngsruns/api/v2/runs/id/" + os.environ[RUNID] + "/barcodes"
    barcodes, response = rest_call(request)
    if not barcodes or response != 200:
        raise BaseException(
            "webserver '{}' error.".format(response) + " from " + request
        )
    print("barcodes:", barcodes)

    files = glob.glob(barcoderdir + "/barcode*/*.fastq.gz")
    # print(files)

    if not files:
        raise Exception("No expected files found in '{}'".format(barcoderdir))

    for name in files:
        barcode = os.path.basename(os.path.dirname(name))
        for item in barcodes:
            if item["barcode"] == barcode:
                newname = os.path.join(
                        args.outputdir,
                        item["sampleid"]
                        + ".fastq.gz",
                    )
                print(name, ">", newname)
                #shutil.copy(name, newname)
                pathlib.Path(newname).symlink_to(name)


# runinfo: {'description': '', 'flowcell': 'FAO81911', 'id': 6, 'name': 'R91', 'project': None}
# /mnt/scratch_dir/verhager/giconvert/20201204_1630_X3_FAO62358_1ec7bfef_0003/guppy_barcoder/barcode16/fastq_runid_fa385ea1740bf6fd66fafc880e3f4f889d8bad37_0.fastq.gz {'barcode': 'barcode16', 'description': '', 'primer_set': 'ArticV3', 'sampleid': '4802000355', 'virus_target': 'Corona'}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--server", help="API server URL", required=True)
    parser.add_argument(
        "inputdir", type=pathlib.Path, help="Input directory (filesystem path).")
    parser.add_argument(
        "outputdir", type=pathlib.Path, help="Output directory (filesystem path).")
    args = parser.parse_args()
    print(args)
    sys.exit(main(args))
