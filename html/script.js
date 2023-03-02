const post = (cb,data) => {
    $.post('https://'+GetParentResourceName()+'/'+cb,data?JSON.stringify(data):"{}");
};

const AvailableMessages = {};
const RegisterMessage = (name,cb) => {
    AvailableMessages[name]=cb;
};

const main = document.getElementById('main');
const grid = document.getElementById('grid');
const form = document.getElementById('form');
const fChild = form.querySelector('form').querySelector('button');
const settings = document.getElementById('settings');
var Translation = {};

const template = document.getElementById('template');

const notifcontainer = document.getElementById('notifications');
const notifications = document.getElementById('notif');
const debug = document.getElementById('debug');

window.addEventListener('message', function (event) {
    let data = event.data;
    if(data.type==='show'){
        main.style.display = data.status?'block':'none';
    }else if(data.type==='translations'){
        data.data=data.data?data.data:{};
        Translation = data.data;
        const translations = document.querySelectorAll('.trscl');
        translations.forEach(elem=>{
            elem.innerHTML=data.data[elem.innerHTML]?data.data[elem.innerHTML]:`Translation [${data.lang}] Not Found`;
        });
    }else if(data.type==='compress'){
        post('compress',{data:Citizen.Compress(JSON.stringify(data.data))});
    }else if(data.type==='decompress'){
        post('decompress',{data:Citizen.Decompress(data.data)});
    }else if(data.type==='addnotif'){
        notifications.innerHTML = data.data;
        setTimeout(()=>{
            if(notifications.innerHTML==data.data){
                notifications.innerHTML="";
            };
        },3000);
    }else if(data.type==='debug'){
        let doc = document.getElementById(data.name);
        if(doc){
            if(data.show){
                doc.innerHTML = data.data
                doc.parentNode.style.display = 'block';
            } else {
                doc.innerHTML = "";
                doc.parentNode.style.display = 'none';
            };
        };
    }else if(data.type==='debugdelete'){
        debug.querySelectorAll('div').forEach(elem=>{
            elem.style.display="none";
            let sp = elem.querySelector('span');
            if(sp){
                sp.innerHTML='';
            };
        });
    }else {
        if(AvailableMessages[data.type]){
            AvailableMessages[data.type](data);
        };
    };
});


let LastOption;
let Settings;

function TrySubmitForm() {
    if(LastOption) {
        SubmitForm(fChild);
    };
};

window.addEventListener('keydown', function (event) {
    if(event.key==='Escape'){
        admin.style.display='none';
        if(!LastOption&&!Settings&&template.style.display=='none'){
            post('nuioff');
        } else if(LastOption) {
            grid.style.display = 'grid';
            form.style.display = 'none';
            LastOption=null;
        } else if(Settings) {
            grid.style.display = 'grid';
            settings.style.display = 'none';
            Settings=null;
        } else {
            template.style.display='none';
            grid.style.display='grid';
        }
    } else if(event.key==='Enter'){
        TrySubmitForm();
    };
});

post('loaded');

const network = document.getElementById('network');
let network_def = false;

function SubmitForm(e) {
    if(!LastOption)return;
    post('spawn', {
        type: 'spawn',
        data: LastOption,
        model: e.parentNode.querySelector('#model').value,
        network: network?.checked
    });
    network.checked = network_def;
    AbortForm();
    post('nuioff');
};

function ChosenOption(e) {
    let start = e.id.substring(0,2);
    if(start==='S_'){
        LastOption = e.id;
        grid.style.display = 'none';
        form.querySelector('form').querySelector('label').textContent = `${Translation['form_title']||"Translation[N/a]"} ${LastOption}`;
        form.style.display = 'block';
    } else if(start==='M_'){
        post('manage', {
            type: 'manage',
            data: e.id
        });
        post('nuioff');
    } else if(start==='A_'){
        if(e.id==='A_Sett'){
            Settings = true;
            grid.style.display = 'none';
            settings.style.display = 'block';
        } else {
            post('addent');
            post('nuioff');
        };
    } else if(start==='T_'){
        if(e.id==='T_Change'){
            grid.style.display = 'none';
            template.style.display = 'grid';
        };
    };
};

function AbortForm() {
    grid.style.display = 'grid';
    form.style.display = 'none';
    LastOption=null;
};

const Setting_data = {};

function SaveSettings(e) {
    let sett = e.parentNode.querySelector('.s-grid').querySelectorAll('.option');
    sett.forEach(elem => {
        Setting_data[elem.value]=elem.checked;
    });
    network_def=Setting_data['networked']!=undefined?Setting_data['networked']:false;
    network.checked = network_def;
    grid.style.display = 'grid';
    settings.style.display = 'none';
    Settings=null;
    post('UpdateSettings', Setting_data);
    post('SaveProject')
};

function TempClicked(e) {
    post('TempSelected',{id:e.id});
};

const admin = document.getElementById('admin');
const sidedata = document.getElementById('mainbar');

function ManageAdmin(e) {
    post('admin',{
        data:e.id
    });
};

RegisterMessage('showadmin', function(data){
    if(data.show){
        admin.style.display='grid';
    }else {
        admin.style.display='none';
    };
});

RegisterMessage('admin', function(data){
    if(data.is){
        sidedata.innerHTML="";
        let temp = `<div class='sidebar-class' id="PMC">
            <div class="sidebar-title sc1">CMP</div>
            <button class="remove_file" onclick="OnAdminClick(this)" type="button">Remove File</button>
            <button class="see_content" onclick="OnAdminClick(this)" type="button">See Content</button>
        </div>`;
        let res = "";
        data.data.forEach(el=> {
            res+=temp.replace('PMC',el).replace('CMP',el);
        });
        sidedata.innerHTML=res;
    }else {
        sidedata.innerHTML="";
        let temp = `<div class='sidebar-class' id="PMC">
            <div class="sidebar-title sc2">CMP</div>
            <button class="load_scene" onclick="OnAdminClick(this)" type="button">Load Scene</button>
            <button class="go_to" onclick="OnAdminClick(this)" type="button">Go To Scene</button>
            <button class="unload_scene" onclick="OnAdminClick(this)" type="button">Unload Scene</button>
            <button class="more" onclick="SeeMore(this)" type="button">More
                <div style="display:none" class="see-more">
                    <div><label for="bucket">Dimension:</label><input class="input" name="bucket" type="number" min="0" max="100"></div>
                    <div onclick="SubmitAdminForm(this)">Save</div>
                </div>
            </button>
        </div>`;
        let res = "";
        data.data.forEach(el=> {
            res+=temp.replace('PMC',el.name).replace('CMP',(el.temp&&('[TEMP] '+el.name.replace('TEMP',''))||'[SCENE] '+el.name));
        });
        sidedata.innerHTML=res;
    };
});

let isopen = null;

function OnAdminClick(e) {
    let scene = e.parentNode.id;
    let id = e.className;
    post('adminselected',{
        command: id,
        file: scene
    })
};

function SeeMore(e) {
    if(!isopen){
        let form = e.querySelector('.see-more');
        form.style.display = 'grid';
        isopen=form;
    };
};

function SubmitAdminForm(e) {
    if(isopen){
        isopen.style.display = 'none';
        setTimeout(()=>{
            isopen=null;
        },0);
    };
    e.parentNode.style.display = 'none';
    let retval = {};
    let input = e.parentNode.querySelectorAll('.input')
    for(let i=0;i<input.length;i++){
        retval[input[i].name]=input[i].value;
    };
    post('setscenedata',{
        file: e.parentNode.parentNode.parentNode.id,
        data: retval
    })
};
