from flask import Flask, jsonify, send_from_directory, request, render_template, make_response
# import random
# import json



FETCHING_VIA_SMB = 0
FETCHING_LOCALLY = 1

if FETCHING_VIA_SMB:
    from smb.SMBConnection import SMBConnection
    from smb.base import NotConnectedError, SMBTimeout
    import time

    SMB_HOST = "192.168.1.1"
    SMB_SHARE = "g"
    SMB_FOLDER = "Slike_Simoncic_1.1.23_3.12.24"
    USERNAME = "X" # fetch from local file that is not under git surveillance
    PASSWORD = "Y" # fetch from local file that is not under git surveillance
    CLIENT_NAME = "website"
    SERVER_NAME = "192.168.1.1"
    PORT = 445

    # SMB Configuration
    conn = SMBConnection(USERNAME, PASSWORD, CLIENT_NAME, SERVER_NAME, use_ntlm_v2=True)
    conn.connect(SMB_HOST, PORT)


elif FETCHING_LOCALLY:
    import os
    ROOT_DIR_IMAGES = "/mnt/server_slike/Slike_Simoncic_1.1.23_3.12.24/"

app = Flask(__name__)






def try_to_reconnect(conn, host, port):
    print("Connection lost! Reconnecting...")
    sleep_time_s = 0.1 
    unsuccessful = True
    while unsuccessful:
            time.sleep(sleep_time_s)  # Wait before retrying
            sleep_time_s = sleep_time_s + 0.1
            if sleep_time_s > 1:
                sleep_time_s = 1
            unsuccessful = not conn.connect(host, port)
            



@app.route("/index")
def index():
    mode = request.args.get("mode", "manual")
    return render_template("index.html", mode=mode)

@app.route("/years")
def get_years():

    if FETCHING_VIA_SMB:
        try:    
        # Attempt to use the connection
            directories = conn.listPath(SMB_SHARE, SMB_FOLDER)
        except NotConnectedError:
            try_to_reconnect(conn, SMB_HOST, PORT)
            directories = conn.listPath(SMB_SHARE, SMB_FOLDER)
        except SMBTimeout:
            print("SAMBA server not responding!")
            time.sleep(10)
            try:
            # Attempt to use the connection
                directories = conn.listPath(SMB_SHARE, SMB_FOLDER)
            except NotConnectedError:
                try_to_reconnect(conn, SMB_HOST, PORT)
                directories = conn.listPath(SMB_SHARE, SMB_FOLDER)
    
    
    elif FETCHING_LOCALLY:
        directories = sorted(os.listdir(ROOT_DIR_IMAGES))

    dirs_names = [d.filename for d in directories if d.isDirectory and d.filename not in ['.', '..'] and not d.filename.startswith('.')]
    items_to_remove = ["Srednja sola", "streha"]
    dirs_names = [item for item in dirs_names if item not in items_to_remove]
    return jsonify(dirs_names)
    # >>> directories = conn.listPath(SMB_SHARE, SMB_FOLDER)
    # >>> directories
    # [<smb.base.SharedFile object at 0x7f80f65ca0>, <smb.base.SharedFile object at 0x7f80f65880>, <smb.base.SharedFile object at 0x7f80f65550>, <smb.base.SharedFile object at 0x7f80f65f40>, <smb.base.SharedFile object at 0x7f80f65eb0>, <smb.base.SharedFile object at 0x7f80f65fa0>, <smb.base.SharedFile object at 0x7f80f65fd0>, <smb.base.SharedFile object at 0x7f80f65f10>, <smb.base.SharedFile object at 0x7f80f65d00>, <smb.base.SharedFile object at 0x7f80f65910>, <smb.base.SharedFile object at 0x7f80f65df0>, <smb.base.SharedFile object at 0x7f80f65460>, <smb.base.SharedFile object at 0x7f80f65d60>, <smb.base.SharedFile object at 0x7f80f65e50>, <smb.base.SharedFile object at 0x7f80f65c40>, <smb.base.SharedFile object at 0x7f80f02040>, <smb.base.SharedFile object at 0x7f80f02070>, <smb.base.SharedFile object at 0x7f80f020a0>, <smb.base.SharedFile object at 0x7f80f020d0>, <smb.base.SharedFile object at 0x7f80f02100>, <smb.base.SharedFile object at 0x7f80f02130>, <smb.base.SharedFile object at 0x7f80f02160>, <smb.base.SharedFile object at 0x7f80f02190>, <smb.base.SharedFile object at 0x7f80f021c0>, <smb.base.SharedFile object at 0x7f80f021f0>, <smb.base.SharedFile object at 0x7f80f02220>, <smb.base.SharedFile object at 0x7f80f02250>, <smb.base.SharedFile object at 0x7f80f02280>, <smb.base.SharedFile object at 0x7f80f022b0>, <smb.base.SharedFile object at 0x7f80f022e0>, <smb.base.SharedFile object at 0x7f80f02310>, <smb.base.SharedFile object at 0x7f80f02340>, <smb.base.SharedFile object at 0x7f80f02370>, <smb.base.SharedFile object at 0x7f80f023a0>, <smb.base.SharedFile object at 0x7f80f023d0>, <smb.base.SharedFile object at 0x7f80f02400>, <smb.base.SharedFile object at 0x7f80f02430>, <smb.base.SharedFile object at 0x7f80f02460>, <smb.base.SharedFile object at 0x7f80f02490>, <smb.base.SharedFile object at 0x7f80f024c0>, <smb.base.SharedFile object at 0x7f80f024f0>]
    # >>> [d.filename for d in directories if d.isDirectory and d.filename not in ['.', '..']]
    # ['2005', '2006', '2007', '2008', '2009', '2010', '2011', '2012', '2012 vse urejeno', '2013', '2013 vse urejeno', '2014', '2014 vse urejeno Razen video Anze krtst', '2015', '2015 vse urejeno', '2016', '2016 NOVO urejanje_29.11.18 in maj 2019', '2017', '2017 urejanje', '2018', '2018 obletn', '2019', '2019 urejanje', '2020', '2021', '2021 urejanje', '2022', '2022 urejanje', '2022 Urejene slike', '2023 Urejene slike', '2024 Urejene slike', 'Nordkapp-osnovni posnetki', 'Slike Dare mobitel', 'Srednja sola', 'streha', 'Tigy', 'trojčki slike']


@app.route("/events/<year>")
def get_events(year):

    if FETCHING_VIA_SMB:

        path = f"{SMB_FOLDER}/{year}"
        try:
            # Attempt to use the connection
            directories = conn.listPath(SMB_SHARE, path)
        except NotConnectedError:
            try_to_reconnect(conn, SMB_HOST, PORT)
            directories = conn.listPath(SMB_SHARE, path)
        except SMBTimeout:
            print("SAMBA server not responding!")
            time.sleep(10)
            try:
                # Attempt to use the connection
                directories = conn.listPath(SMB_SHARE, path)
            except NotConnectedError:
                try_to_reconnect(conn, SMB_HOST, PORT)
                directories = conn.listPath(SMB_SHARE, path)

    elif FETCHING_LOCALLY:
        directories = sorted(os.listdir(f"{ROOT_DIR_IMAGES}/{year}"))


    dirs_names = [d.filename for d in directories if d.isDirectory and d.filename not in ['.', '..'] and not d.filename.startswith('.')]
    return jsonify(dirs_names)

@app.route("/images/<year>/<event>")
def get_images(year, event):

    if FETCHING_VIA_SMB:

        path = f"{SMB_FOLDER}/{year}/{event}"
        try:
            # Attempt to use the connection
            files = conn.listPath(SMB_SHARE, path)
        except NotConnectedError:
            try_to_reconnect(conn, SMB_HOST, PORT)
            files = conn.listPath(SMB_SHARE, path)
        except SMBTimeout:
            print("SAMBA server not responding!")
            time.sleep(10)
            try:    
                # Attempt to use the connection
                files = conn.listPath(SMB_SHARE, path)
            except NotConnectedError:
                try_to_reconnect(conn, SMB_HOST, PORT)
                files = conn.listPath(SMB_SHARE, path)
    
    elif FETCHING_LOCALLY:
        files = sorted(os.listdir(f"{ROOT_DIR_IMAGES}/{year}/{event}"))

    images = [f.filename for f in files if f.filename.lower().endswith((".png", ".jpg", ".jpeg"))]
    return jsonify(images)

@app.route("/image/<year>/<event>/<image_name>")
def serve_image(year, event, image_name):
    local_path = f"/tmp/{image_name}"


    try:
        # Attempt to use the connection
        with open(local_path, "wb") as f:
            conn.retrieveFile(SMB_SHARE, f"{SMB_FOLDER}/{year}/{event}/{image_name}", f)
        return send_from_directory("/tmp", image_name)

    except NotConnectedError:
        try_to_reconnect(conn, SMB_HOST, PORT)
        with open(local_path, "wb") as f:
            conn.retrieveFile(SMB_SHARE, f"{SMB_FOLDER}/{year}/{event}/{image_name}", f)
        return send_from_directory("/tmp", image_name)

    except SMBTimeout:
        print("SAMBA server not responding!")
        time.sleep(10)
        try:
            # Attempt to use the connection
            with open(local_path, "wb") as f:
                conn.retrieveFile(SMB_SHARE, f"{SMB_FOLDER}/{year}/{event}/{image_name}", f)
            return send_from_directory("/tmp", image_name)

        except NotConnectedError:
            try_to_reconnect(conn, SMB_HOST, PORT)
            with open(local_path, "wb") as f:
                conn.retrieveFile(SMB_SHARE, f"{SMB_FOLDER}/{year}/{event}/{image_name}", f)
            return send_from_directory("/tmp", image_name)



if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)