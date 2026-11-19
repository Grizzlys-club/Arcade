(()=>{
'use strict';
const ALL=[["penalty","Penalty-Duell","Sport"],["goalie","Torwart-Panik","Sport"],["airhockey","Air-Hockey","Sport"],["puckgolf","Puck-Golf","Sport"],["ballrain","Ballregen","Sport"],["powershot","Power-Schuss","Sport"],["hotpuck","Heisser Puck","Sport"],["sumo","Eis-Sumo","Sport"],["ninja","Puck-Ninja","Sport"],["juggle","Ballhalten","Sport"],["quiz","Unihockey-Quiz","Sport"],["duel","Schläger-Duell","Sport"],["dash","Bären-Sprint","Sport"],["flappy","Flatter-Bär","Party"],["hopper","Bären-Hüpfer","Party"],["stack","Bären-Turm","Party"],["simon","Grizzly Says","Party"],["reaction","Reaktions-Duell","Party"],["numbers","Zahlen-Jagd","Party"],["colors","Farben-Falle","Party"],["balance","Eis-Balance","Party"],["territory","Revierkampf","Party"],["tapsprint","Tap-Sprint","Party"],["whack","Puck-Jagd","Sport"],["memory","Bären-Memory","Party"],["curling","Eis-Curling","Sport"],["slalom","Slalom-Dribbling","Sport"],["pong","Puck-Pong","Sport"],["bowling","Bären-Bowling","Party"],["tugwar","Tauziehen","Party"],["darts","Bären-Darts","Party"],["hoops","Korbjagd","Sport"],["hurdles","Hürdenlauf","Party"],["mathduel","Kopfrechnen","Party"],["rhythm","Takt-Tipper","Party"],["billiard","Puck-Billard","Sport"],["arrows","Pfeil-Panik","Party"],["oddone","Ausreisser","Party"],["compare","Grösser oder kleiner","Party"],["sorter","Farb-Sortierer","Party"],["dodge","Puck-Ausweichen","Sport"],["cave","Höhlenflug","Party"],["pendulum","Pendel-Wurf","Sport"],["count","Puck-Zähler","Party"],["stoptime","Zeit-Stopp","Party"],["slide","Eis-Rutsch","Sport"],["snowball","Schneeballschlacht","Party"],["zigzag","Zickzack-Bär","Party"],["lightsout","Lichter aus","Party"],["reflex","Finger-Blitz","Party"]];
const G=window.GAMES,R=window.Runner;
const NAME={};ALL.forEach(a=>NAME[a[0]]=a[1]);
const LV=['Anfänger','Leicht','Okay','Stark','Grizzly'],SK=[.04,.14,.26,.42,.64];
const $app=document.getElementById('app');
const esc=s=>String(s).replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));

/* Speicher */
const KEY='ga.web.v1';
let S={xp:0,played:0,wins:0,diff:2,names:['Spieler 1','Spieler 2','Spieler 3','Spieler 4'],rec:{}};
try{const j=JSON.parse(localStorage.getItem(KEY)||'null');if(j)S=Object.assign(S,j)}catch(e){}
const save=()=>{try{localStorage.setItem(KEY,JSON.stringify(S))}catch(e){}};
const level=xp=>Math.floor(Math.sqrt(xp/40))+1;

/* Zustand */
const ctx={n:1,diff:S.diff,mode:'play',rounds:5,sess:null,tour:null,inGame:false,ov:'',confirmReset:false};
const canvas=document.createElement('canvas');canvas.width=360;canvas.height=640;canvas.setAttribute('aria-label','Spielfeld');
R.mount(canvas);

/* Verlauf: Zurück-Wischen bleibt in der App */
function push(name){history.pushState({s:name},'','#'+name);render(name)}
function replace(name){history.replaceState({s:name},'','#'+name);render(name)}
history.replaceState({s:'guard'},'','#');history.pushState({s:'hub'},'','#hub');
window.addEventListener('popstate',e=>{
  const s=e.state&&e.state.s;
  if(s==='guard'){history.pushState({s:'hub'},'','#hub');if(ctx.inGame)pause();else render('hub');return}
  if(ctx.inGame){history.pushState({s:'game'},'','#game');pause();return}
  if(!s||!SCREENS[s]||s==='game'||(s==='result'&&!ctx.res)){render('hub');return}
  render(s)});

function toast(t){let el=document.getElementById('toast');if(!el){el=document.createElement('div');el.id='toast';el.style.cssText='position:fixed;left:50%;bottom:30px;transform:translateX(-50%);background:#fff;color:#1B1C1F;font-weight:700;padding:12px 18px;border-radius:99px;z-index:9;max-width:90vw;text-align:center';document.body.appendChild(el)}
  el.textContent=t;el.style.display='block';clearTimeout(toast.t);toast.t=setTimeout(()=>el.style.display='none',2200)}

const bar=(title,back=true,extra='')=>`<div class="bar">${back?'<button class="ib" data-a="back" aria-label="Zurück">‹</button>':''}<h2>${title}</h2>${extra}</div>`;
const compatible=(id,n)=>G[id]&&(!G[id].versus||n<=G[id].maxPlayers);
const seatsOf=()=>{const h=[];for(let i=0;i<ctx.n;i++)h.push({name:(S.names[i]||'Spieler '+(i+1)).trim()||'Spieler '+(i+1),cpu:false});if(ctx.n===1)h.push({name:'Computer',cpu:true});return h};

/* ---------- Bildschirme ---------- */
const SCREENS={
hub(){const l=level(S.xp),a=40*(l-1)**2,b=40*l*l,p=Math.round((S.xp-a)/(b-a)*100);
 return `<div class="body" style="justify-content:center">
 <div class="hero"><img src="img/icon1024.png" alt="Logo Unihockey am Greifensee Grizzlys"><h1>GRIZZLYS<br><b>ARCADE</b></h1></div>
 <div class="card lvl"><span class="n">${l}</span><div style="flex:1"><div class="mut" style="margin-bottom:5px">Level · ${S.xp} Erfahrungspunkte</div><div class="xp"><i style="width:${p}%"></i></div></div></div>
 <button class="btn" data-a="play">Spielen</button>
 <button class="btn alt" data-a="tour">Turnier</button>
 <div class="row"><button class="btn alt sm" style="flex:1" data-a="stats">Rekorde</button><button class="btn alt sm" style="flex:1" data-a="settings">Einstellungen</button></div>
 <a class="lnk" href="index.html">Zur Webseite</a></div>`},

setup(){const t=ctx.mode==='tour';
 const names=[...Array(ctx.n)].map((_,i)=>`<div><label class="f" for="nm${i}">Spieler ${i+1}</label><input class="t" id="nm${i}" data-name="${i}" maxlength="14" value="${esc(S.names[i])}" autocomplete="off"></div>`).join('');
 return bar(t?'Turnier':'Spielen')+`<div class="body">
 <div class="card"><label class="f">Wie viele Spieler?</label><div class="row">${[1,2,3,4].map(n=>`<button class="chip" data-n="${n}" aria-pressed="${ctx.n===n}">${n}</button>`).join('')}</div>
 <p class="mut" style="margin-top:10px">${ctx.n===1?'Du spielst gegen den Computer.':'Alle spielen am selben Gerät. Bei Punktespielen kommt jeder der Reihe nach dran.'}</p></div>
 <div class="card" style="display:grid;gap:12px">${names}</div>
 ${ctx.n===1?`<div class="card"><label class="f">Stärke des Computers</label><div class="row">${LV.map((x,i)=>`<button class="chip" data-d="${i}" aria-pressed="${ctx.diff===i}">${x}</button>`).join('')}</div></div>`:''}
 ${t?`<div class="card"><label class="f">Anzahl Runden</label><div class="row">${[3,5,7,10,15].map(n=>`<button class="chip" data-r="${n}" aria-pressed="${ctx.rounds===n}">${n}</button>`).join('')}</div><p class="mut" style="margin-top:10px">Pro Runde wird ein Spiel ausgelost. Das Finale zählt doppelt.</p></div>`:''}
 <button class="btn" data-a="${t?'tourgo':'pick'}">${t?'Turnier starten':'Weiter'}</button></div>`},

picker(){const ids=Object.keys(G),rest=ALL.filter(a=>!G[a[0]]);
 const tile=(id,ok)=>`<button class="tile${ok?'':' off'}" data-g="${id}" data-ok="${ok?1:0}"><img src="img/games/${id}.jpg" alt="" loading="lazy"><span class="t">${NAME[id]}<small>${ok?G[id]?G[id].sub:'':'Nur in der App'}</small></span></button>`;
 return bar('Spiel wählen')+`<div class="body"><h3 class="sec">Im Browser spielbar</h3><div class="grid">${ids.map(id=>tile(id,compatible(id,ctx.n))).join('')}</div>
 <h3 class="sec" style="margin-top:14px">Weitere ${rest.length} Spiele</h3><p class="mut">Diese gibt es in der App für das iPhone.</p><div class="grid">${rest.map(a=>tile(a[0],false)).join('')}</div></div>`},

intro(){const id=ctx.sess.id,g=G[id],sd=ctx.sess.seats;
 return bar(g.name)+`<div class="body intro"><img src="img/games/${id}.jpg" alt="Spielbild ${g.name}">
 <div class="card"><p>${g.help}</p></div>
 <div class="card"><b>Dabei:</b> ${sd.map(s=>esc(s.name)).join(', ')}<p class="mut" style="margin-top:6px">${g.versus?(ctx.n===2?'Zu zweit am selben Bildschirm: '+esc(sd[0].name)+' spielt unten, '+esc(sd[1].name)+' oben.':'Du spielst unten, der Computer oben.'):(sd.length>1?'Jeder spielt für sich, der Reihe nach. Gib das Gerät weiter, wenn du fertig bist.':'')}</p></div>
 <button class="btn" data-a="start">Start</button></div>`},

game(){const g=G[ctx.sess.id];
 return `<div class="bar"><button class="ib" data-a="pause" aria-label="Pause">❚❚</button><h2>${g.name}</h2></div><div class="stage"><div class="frame" id="frame"></div></div>`},

result(){const r=ctx.res,t=ctx.tour,fin=t&&t.round===t.rounds-1;
 const rows=r.order.map((si,k)=>{const s=r.seats[si],sc=r.scores[si];return `<div class="rank${k===0?' win':''}"><span class="p">${r.pos[k]}</span><span class="nm">${esc(s.name)}</span><span class="sc">${sc==null?(k===0?'Sieg':''):sc+(G[ctx.sess.id].unit||'')}${t?'<br>+'+r.pts[si]+' Pkt':''}</span></div>`}).join('');
 return `<div class="body" style="justify-content:center"><div style="text-align:center"><div class="mut">${G[ctx.sess.id].name}</div><div class="big">${r.tie?'Unentschieden':esc(r.seats[r.order[0]].name)+' gewinnt'}</div>${r.gain?`<div class="mut" style="margin-top:6px">+${r.gain} Erfahrungspunkte${r.rec?' · Neuer Rekord!':''}</div>`:''}</div>
 <div style="display:grid;gap:10px">${rows}</div>
 ${t?`<button class="btn" data-a="next">${fin?'Zur Siegerehrung':'Nächste Runde'}</button>`:`<button class="btn" data-a="again">Nochmal</button><button class="btn alt" data-a="pick">Anderes Spiel</button><button class="btn alt sm" data-a="home">Hauptmenü</button>`}</div>`},

tour(){const t=ctx.tour,fin=t.round===t.rounds-1;
 const tbl=t.seats.map((s,i)=>`<tr><td>${esc(s.name)}</td><td>${t.points[i]} Pkt</td></tr>`).join('');
 return bar('Runde '+(t.round+1)+' von '+t.rounds)+`<div class="body">
 <div class="card" style="text-align:center"><div class="mut">${fin?'Finale · zählt doppelt':'Als Nächstes'}</div><div class="big" style="font-size:42px;margin-top:4px">${NAME[t.next]}</div></div>
 <div class="intro"><img src="img/games/${t.next}.jpg" alt=""></div>
 <div class="card"><table>${tbl}</table></div>
 <button class="btn" data-a="tourplay">Spielen</button></div>`},

podium(){const t=ctx.tour,ord=t.seats.map((_,i)=>i).sort((a,b)=>t.points[b]-t.points[a]);
 const top=ord.slice(0,3),h=[130,170,100];const visual=top.length===1?[0]:top.length===2?[1,0]:[1,0,2];
 const pod=visual.map(k=>`<div class="${k===0?'w':''}" style="height:${h[k]||90}px"><b>${k+1}</b>${esc(t.seats[top[k]].name)}<span class="mut">${t.points[top[k]]} Pkt</span></div>`).join('');
 return bar('Siegerehrung',false)+`<div class="body" style="justify-content:center"><div style="text-align:center"><div style="font-size:64px">🏆</div><div class="big">${esc(t.seats[ord[0]].name)}</div><div class="mut">ist Turniersieger</div></div>
 <div class="pod">${pod}</div><button class="btn" data-a="tour">Neues Turnier</button><button class="btn alt" data-a="home">Hauptmenü</button></div>`},

stats(){const rows=Object.keys(G).map(id=>{const r=S.rec[id];return `<tr><td>${G[id].name}</td><td>${r==null?'–':(r+(G[id].unit||''))}</td></tr>`}).join('');
 return bar('Rekorde')+`<div class="body"><div class="card"><table><tr><td>Gespielte Spiele</td><td>${S.played}</td></tr><tr><td>Siege</td><td>${S.wins}</td></tr><tr><td>Level</td><td>${level(S.xp)}</td></tr></table></div>
 <div class="card"><b>Beste Ergebnisse</b><table style="margin-top:6px">${rows}</table></div></div>`},

settings(){return bar('Einstellungen')+`<div class="body">
 <div class="card"><label class="f">Standard-Stärke des Computers</label><div class="row">${LV.map((x,i)=>`<button class="chip" data-sd="${i}" aria-pressed="${S.diff===i}">${x}</button>`).join('')}</div></div>
 <div class="card"><label class="f">Fortschritt</label><p class="mut" style="margin-bottom:10px">Level, Rekorde und Namen liegen nur in deinem Browser.</p><button class="btn alt sm" data-a="reset">${ctx.confirmReset?'Wirklich alles löschen?':'Zurücksetzen'}</button></div>
 <div class="card"><a class="lnk" href="datenschutz.html">Datenschutz</a><a class="lnk" href="impressum.html">Impressum</a><a class="lnk" href="index.html">Zur Webseite</a></div>
 <p class="mut" style="text-align:center">Grizzlys Arcade im Browser. Alle 50 Spiele gibt es in der App.</p></div>`}
};

function render(name){
  if(name!=='game'){ctx.inGame=false;R.stop()}
  $app.innerHTML=SCREENS[name]();
  if(name==='game'){document.getElementById('frame').appendChild(canvas);const ov=document.createElement('div');ov.className='ov';ov.id='ov';ov.hidden=true;document.getElementById('frame').appendChild(ov);if(ctx.ov)setOv(ctx.ov);fit()}
  const b=$app.querySelector('.body');if(b)b.scrollTop=0;
}
function fit(){const st=document.querySelector('.stage'),fr=document.getElementById('frame');if(!st||!fr)return;let h=st.clientHeight-10-parseFloat(getComputedStyle(st).paddingBottom||0),w=h*9/16;if(w>st.clientWidth-20){w=st.clientWidth-20;h=w*16/9}fr.style.width=Math.floor(w)+'px';fr.style.height=Math.floor(h)+'px'}
window.addEventListener('resize',fit);
function setOv(html){ctx.ov=html;const ov=document.getElementById('ov');if(!ov)return;ov.innerHTML=html;ov.hidden=!html}

/* ---------- Spielablauf ---------- */
function begin(id,fromReplace){
  ctx.sess={id,seats:seatsOf(),scores:[],turn:0};ctx.sess.mode=ctx.tour?'tour':'play';
  ctx.inGame=true;ctx.ov='';
  if(fromReplace)replace('game');else push('game');
  ctx.inGame=true;
  nextTurn()}
function nextTurn(){
  const s=ctx.sess,g=G[s.id],humans=s.seats.filter(x=>!x.cpu);
  if(g.versus){
    const two=s.seats.length===2&&!s.seats[1].cpu;
    setOv(`<h2>${g.name}</h2><p>${two?esc(s.seats[0].name)+' spielt unten, '+esc(s.seats[1].name)+' oben.':esc(s.seats[0].name)+' spielt unten gegen den Computer ('+LV[ctx.diff]+').'}</p><button class="btn" data-a="go">Los</button>`);
    ctx.run=()=>{setOv('');ctx.inGame=true;R.play(s.id,{skill:SK[ctx.diff],two},res=>finish({winner:res.winner}))};return}
  if(s.turn>=humans.length){
    const cpu=s.seats.findIndex(x=>x.cpu);if(cpu>=0)s.scores[cpu]=g.cpuScore(SK[ctx.diff]);
    finish({scores:s.scores});return}
  const me=humans[s.turn];
  setOv(`<p>${humans.length>1?'Gerät an':''}</p><h2>${esc(me.name)}</h2><p>${g.help}</p><button class="btn" data-a="go">Los</button>`);
  ctx.run=()=>{setOv('');R.play(s.id,{skill:SK[ctx.diff]},res=>{s.scores[s.seats.indexOf(me)]=res.score;s.turn++;
    setOv(`<h2>${res.title}</h2><p>${esc(res.sub)}</p><button class="btn" data-a="cont">Weiter</button>`)})};
}
function finish(o){
  const s=ctx.sess,g=G[s.id],n=s.seats.length;let order;
  if(o.winner!=null){order=[o.winner,1-o.winner];if(n<2)order=[0]}
  else{const hi=g.best==='hoch';order=s.seats.map((_,i)=>i).sort((a,b)=>hi?o.scores[b]-o.scores[a]:o.scores[a]-o.scores[b])}
  const pos=[];order.forEach((si,k)=>{const prev=k&&o.scores&&o.scores[si]===o.scores[order[k-1]]?pos[k-1]:k+1;pos.push(prev)});
  const scores=o.winner!=null?s.seats.map(()=>null):o.scores,pts=s.seats.map(()=>0);
  order.forEach((si,k)=>{pts[si]=(n-pos[k]+1)*(ctx.tour&&ctx.tour.round===ctx.tour.rounds-1?2:1)});
  // Fortschritt der Menschen
  const tie=pos.length>1&&pos[0]===pos[1];let gain=0,rec=false;const winnerHuman=!s.seats[order[0]].cpu;
  s.seats.forEach((st,i)=>{if(st.cpu)return;S.played++;gain+=10;
    if(i===order[0]&&!tie){S.wins++;gain+=15}
    if(g.best&&scores[i]!=null){const old=S.rec[s.id],hi=g.best==='hoch';if(old==null||(hi?scores[i]>old:scores[i]<old)){if(!(hi&&scores[i]<=0)){S.rec[s.id]=scores[i];rec=true}}}});
  S.xp+=gain;save();
  if(ctx.tour)ctx.tour.points=ctx.tour.points.map((p,i)=>p+pts[i]);
  ctx.res={seats:s.seats,order,pos,scores,pts,gain,rec,winnerHuman,tie};
  ctx.inGame=false;replace('result');
}
function pause(){if(!ctx.inGame)return;R.pause();ctx.prevOv=ctx.ov;setOv('<h2>Pause</h2><button class="btn" data-a="resume">Weiterspielen</button><button class="btn alt" data-a="quit">Spiel beenden</button>')}

/* ---------- Eingaben ---------- */
$app.addEventListener('click',e=>{
  const t=e.target.closest('button,a');if(!t||t.tagName==='A')return;
  const d=t.dataset;
  if(d.n){ctx.n=+d.n;render('setup');return}
  if(d.d){ctx.diff=+d.d;S.diff=ctx.diff;save();render('setup');return}
  if(d.r){ctx.rounds=+d.r;render('setup');return}
  if(d.sd){S.diff=+d.sd;ctx.diff=S.diff;save();render('settings');return}
  if(d.g){if(d.ok!=='1'){toast(G[d.g]?'Dieses Spiel geht nur mit höchstens 2 Spielern.':'Dieses Spiel gibt es in der App.');return}
    ctx.sess={id:d.g,seats:seatsOf()};push('intro');return}
  switch(d.a){
   case'back':history.back();break;
   case'play':ctx.mode='play';ctx.tour=null;ctx.n=Math.min(ctx.n,4);ctx.diff=S.diff;push('setup');break;
   case'tour':ctx.mode='tour';ctx.tour=null;ctx.diff=S.diff;if(location.hash==='#podium')replace('setup');else push('setup');break;
   case'stats':push('stats');break;
   case'settings':ctx.confirmReset=false;push('settings');break;
   case'pick':ctx.tour=null;if(location.hash==='#result')replace('picker');else push('picker');break;
   case'start':begin(ctx.sess.id);break;
   case'go':ctx.run&&ctx.run();break;
   case'cont':nextTurn();break;
   case'again':begin(ctx.sess.id,true);break;
   case'home':ctx.tour=null;replace('hub');break;
   case'pause':pause();break;
   case'resume':setOv(ctx.prevOv||'');R.resume();break;
   case'quit':ctx.inGame=false;R.stop();ctx.ov='';history.back();break;
   case'tourgo':{const seats=seatsOf();ctx.tour={round:0,rounds:ctx.rounds,seats,points:seats.map(()=>0),last:null,next:null};pickRound();push('tour');break}
   case'tourplay':begin(ctx.tour.next);break;
   case'next':{const tr=ctx.tour;tr.round++;if(tr.round>=tr.rounds)replace('podium');else{pickRound();replace('tour')}break}
   case'reset':if(ctx.confirmReset){S={xp:0,played:0,wins:0,diff:2,names:['Spieler 1','Spieler 2','Spieler 3','Spieler 4'],rec:{}};ctx.diff=2;save();ctx.confirmReset=false;toast('Fortschritt gelöscht')}else ctx.confirmReset=true;render('settings');break;
  }});
$app.addEventListener('input',e=>{const i=e.target.dataset.name;if(i!=null){S.names[+i]=e.target.value;save()}});
function pickRound(){const t=ctx.tour,pool=Object.keys(G).filter(id=>compatible(id,ctx.n)&&id!==t.last);t.next=pool[Math.floor(Math.random()*pool.length)];t.last=t.next}
window.__app={ctx,S,render};
render('hub');
})();
