const post = (cb,data) => {
    $.post('https://'+GetParentResourceName()+'/'+cb,data?JSON.stringify(data):"{}");
};

const main = document.getElementById('main');
const grid = document.getElementById('grid');
const form = document.getElementById('form');
const fChild = form.querySelector('form').querySelector('button');
const settings = document.getElementById('settings');
var Translation = {};

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
        if(!LastOption&&!Settings){
            post('nuioff');
        } else if(LastOption){
            grid.style.display = 'grid';
            form.style.display = 'none';
            LastOption=null;
        } else {
            grid.style.display = 'grid';
            settings.style.display = 'none';
            Settings=null;
        };
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