(()=>{
'use strict';
const ALL=[["penalty","Penalty-Duell","Sport"],["goalie","Torwart-Panik","Sport"],["airhockey","Air-Hockey","Sport"],["puckgolf","Puck-Golf","Sport"],["ballrain","Ballregen","Sport"],["powershot","Power-Schuss","Sport"],["hotpuck","Heisser Puck","Sport"],["sumo","Eis-Sumo","Sport"],["ninja","Puck-Ninja","Sport"],["juggle","Ballhalten","Sport"],["quiz","Unihockey-Quiz","Sport"],["duel","Schläger-Duell","Sport"],["dash","Bären-Sprint","Sport"],["flappy","Flatter-Bär","Party"],["hopper","Bären-Hüpfer","Party"],["stack","Bären-Turm","Party"],["simon","Grizzly Says","Party"],["reaction","Reaktions-Duell","Party"],["numbers","Zahlen-Jagd","Party"],["colors","Farben-Falle","Party"],["balance","Eis-Balance","Party"],["territory","Revierkampf","Party"],["tapsprint","Tap-Sprint","Party"],["whack","Puck-Jagd","Sport"],["memory","Bären-Memory","Party"],["curling","Eis-Curling","Sport"],["slalom","Slalom-Dribbling","Sport"],["pong","Puck-Pong","Sport"],["bowling","Bären-Bowling","Party"],["tugwar","Tauziehen","Party"],["darts","Bären-Darts","Party"],["hoops","Korbjagd","Sport"],["hurdles","Hürdenlauf","Party"],["mathduel","Kopfrechnen","Party"],["rhythm","Takt-Tipper","Party"],["billiard","Puck-Billard","Sport"],["arrows","Pfeil-Panik","Party"],["oddone","Ausreisser","Party"],["compare","Grösser oder kleiner","Party"],["sorter","Farb-Sortierer","Party"],["dodge","Puck-Ausweichen","Sport"],["cave","Höhlenflug","Party"],["pendulum","Pendel-Wurf","Sport"],["count","Puck-Zähler","Party"],["stoptime","Zeit-Stopp","Party"],["slide","Eis-Rutsch","Sport"],["snowball","Schneeballschlacht","Party"],["zigzag","Zickzack-Bär","Party"],["lightsout","Lichter aus","Party"],["reflex","Finger-Blitz","Party"]];
const G=window.GAMES,R=window.Runner;
const NAME={};ALL.forEach(a=>NAME[a[0]]=a[1]);
const LV=['Anfänger','Leicht','Okay','Stark','Grizzly'],SK=[.04,.14,.26,.42,.64];
const $app=document.getElementById('app');
const esc=s=>String(s).replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));

/* Speicher */
const M=window.META;
const KEY='ga.web.v1';
const defS=()=>({xp:0,played:0,wins:0,diff:2,names:['Spieler 1','Spieler 2','Spieler 3','Spieler 4'],rec:{},coins:0,totalCoins:0,unlocked:['classic','orange','ice','pink'],skinIds:['orange','classic','ice','pink'],ach:[],daily:{date:'',games:0,wins:0,goals:0,balls:0,quiz:0,kinds:[],claimed:[]},streak:0,lastLogin:'',lastWheel:'',items:[],titleId:'rookie',cheerId:'classic',coinBoost:0,xpBoost:0,goals:0,balls:0,quiz:0,hits:0,bestReact:0,tWon:0,tPlayed:0,kinds:[],sound:true});
let S=defS();
try{const j=JSON.parse(localStorage.getItem(KEY)||'null');if(j)S=Object.assign(S,j)}catch(e){}
const save=()=>{try{localStorage.setItem(KEY,JSON.stringify(S))}catch(e){}};
function rollDaily(){const t=M.key();if(S.daily.date!==t)S.daily={date:t,games:0,wins:0,goals:0,balls:0,quiz:0,kinds:[],claimed:[]};
  if(S.lastLogin!==t){const y=new Date();y.setDate(y.getDate()-1);S.streak=S.lastLogin===M.key(y)?S.streak+1:1;S.lastLogin=t}save()}
rollDaily();
const lvl=()=>M.levelInfo(S.xp);
const skinOf=id=>M.SKINS.find(k=>k.id===id)||M.SKINS[0];
const cheerOf=()=>M.CHEERS.find(c=>c.id===S.cheerId)||M.CHEERS[0];
const titleOf=()=>M.TITLES.find(t=>t.id===S.titleId)||M.TITLES[0];
function addCoins(n){S.coins+=n;S.totalCoins+=n}
function addXP(n){const b=lvl().level;S.xp+=n;const a=lvl().level,out=[];for(let l=b+1;l<=a;l++){addCoins(20+l*5);out.push('Level '+l+': '+M.rank(l)+' +'+(20+l*5)+' Münzen')}return out}
function checkAch(){const out=[];M.ACH.forEach(a=>{if(!S.ach.includes(a.id)&&a.check(S)){S.ach.push(a.id);addCoins(a.reward);out.push('Erfolg: '+a.title+' +'+a.reward)}});return out}
function checkDaily(){const out=[];M.todays().forEach(t=>{if(t.prog(S.daily)>=t.goal&&!S.daily.claimed.includes(t.id)){S.daily.claimed.push(t.id);addCoins(t.reward);out.push('Tagesaufgabe: '+t.title+' +'+t.reward)}});return out}
const canWheel=()=>S.lastWheel!==M.key();
/* Töne (einfach, per Einstellung abschaltbar) */
let AC=null;function beep(f,d,t){if(!S.sound)return;try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();const o=AC.createOscillator(),g=AC.createGain();o.type=t||'sine';o.frequency.value=f;g.gain.value=.06;o.connect(g);g.connect(AC.destination);o.start();g.gain.exponentialRampToValueAtTime(.0001,AC.currentTime+d);o.stop(AC.currentTime+d)}catch(e){}}
function confetti(){if(matchMedia('(prefers-reduced-motion:reduce)').matches)return;const pal=cheerOf().pal;for(let i=0;i<46;i++){const e=document.createElement('i');e.className='cf';e.style.left=Math.random()*100+'vw';e.style.background=pal[i%pal.length];e.style.animationDelay=Math.random()*.6+'s';document.body.appendChild(e);setTimeout(()=>e.remove(),3400)}}
const STAT={goals:['penalty','powershot','hoops','puckgolf'],balls:['ballrain','goalie','juggle'],hits:['darts','snowball','whack','sorter','ninja']};

/* Zustand */
const ctx={n:1,diff:S.diff,mode:'play',rounds:5,sess:null,tour:null,inGame:false,ov:'',confirmReset:false,tab:'skins',card:0,spin:false};
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
const seatsOf=()=>{const h=[];for(let i=0;i<ctx.n;i++)h.push({name:(S.names[i]||'Spieler '+(i+1)).trim()||'Spieler '+(i+1),cpu:false,skin:S.skinIds[i]});if(ctx.n===1)h.push({name:'Computer',cpu:true,skin:'classic'});return h};
const coin='<span class="coin"></span>';
const gamesFor=n=>Object.keys(G).filter(id=>compatible(id,n));
const featured=()=>{const p=gamesFor(ctx.n);return p[M.doy()%p.length]};

/* ---------- Bildschirme ---------- */
const SCREENS={
hub(){const L=lvl(),p=Math.round(L.into/L.need*100),tasks=M.todays(),done=tasks.filter(t=>S.daily.claimed.includes(t.id)).length,f=featured();
 return `<div class="body">
 <div class="top"><span class="pill">${coin}${S.coins}</span><span class="pill">🔥 ${S.streak} ${S.streak===1?'Tag':'Tage'}</span><span style="flex:1"></span><button class="ib" data-a="settings" aria-label="Einstellungen">⚙</button></div>
 <div class="hero"><img src="img/icon1024.png" alt="Logo Unihockey am Greifensee Grizzlys" style="width:92px;height:92px"><h1 style="font-size:40px">GRIZZLYS<br><b>ARCADE</b></h1></div>
 <div class="card lvl"><span class="n">${L.level}</span><div style="flex:1"><div class="mut" style="margin-bottom:5px">${titleOf().id==='rookie'?M.rank(L.level):M.rank(L.level)+' · '+titleOf().name} · ${L.into}/${L.need} XP</div><div class="xp"><i style="width:${p}%"></i></div></div></div>
 <button class="tile" style="flex-direction:row;align-items:center" data-g="${f}" data-ok="1"><img src="img/games/${f}.jpg" alt="" style="width:96px;aspect-ratio:4/3"><span class="t" style="flex:1"><small style="color:var(--or);font-weight:700">Spiel des Tages</small>${NAME[f]}</span><span style="padding:0 14px;font-size:22px;color:var(--or)">▶</span></button>
 <button class="btn" data-a="play">${ALL.length} Spiele</button>
 <div class="row"><button class="btn alt sm" style="flex:1" data-a="tour">Turnier</button><button class="btn alt sm" style="flex:1" data-a="random">Zufall</button></div>
 <div class="row"><button class="btn alt sm" style="flex:1" data-a="shop">Shop</button><button class="btn alt sm" style="flex:1" data-a="stats">Stats</button><button class="btn alt sm" style="flex:1" data-a="ach">Erfolge</button><button class="btn alt sm rel" style="flex:1" data-a="wheel">Bonus${canWheel()?'<i class="dot"></i>':''}</button></div>
 <button class="card" style="all:unset;box-sizing:border-box;display:block;cursor:pointer;background:var(--card);border:2px solid var(--line);border-radius:18px;padding:14px 16px" data-a="daily"><b>Tagesaufgaben ${done}/${tasks.length}</b><div class="pb" style="margin-top:8px"><i style="width:${done/tasks.length*100}%"></i></div></button>
 <a class="lnk" href="index.html">Zur Webseite</a></div>`},

shop(){const own=id=>S.unlocked.includes(id);const tabs=[['skins','Skins'],['titles','Titel'],['cheers','Jubel'],['boosts','Booster']];
 let b='';
 if(ctx.tab==='skins'){const c=ctx.card;b=`<div class="card"><label class="f">Skin für</label><div class="row">${[0,1,2,3].map(i=>`<button class="chip" data-card="${i}" aria-pressed="${ctx.card===i}">${esc((S.names[i]||'Spieler '+(i+1)))}</button>`).join('')}</div></div>
  <div class="sk">${M.SKINS.map(k=>{const o=own(k.id),on=S.skinIds[c]===k.id;return `<div class="item${on?' on':''}">${M.bearSVG(k,64)}<div class="i"><b>${k.name}</b><span class="mut">Trikot Nr. ${k.num}</span></div>${o?`<button class="btn${on?' alt':''} sm" data-eq="${k.id}">${on?'Aktiv':'Wählen'}</button>`:`<button class="btn sm" data-buy="${k.id}" ${S.coins<k.price?'disabled':''}>${coin}${k.price}</button>`}</div>`}).join('')}</div>`}
 if(ctx.tab==='titles')b=M.TITLES.map(t=>{const o=t.price===0||S.items.includes(t.id),on=S.titleId===t.id;return `<div class="item${on?' on':''}"><div class="i"><b>${t.name}</b><span class="mut">${t.detail}</span></div>${o?`<button class="btn${on?' alt':''} sm" data-eqt="${t.id}">${on?'Aktiv':'Wählen'}</button>`:`<button class="btn sm" data-buyi="${t.id}" ${S.coins<t.price?'disabled':''}>${coin}${t.price}</button>`}</div>`}).join('');
 if(ctx.tab==='cheers')b=M.CHEERS.map(t=>{const o=t.price===0||S.items.includes('c_'+t.id),on=S.cheerId===t.id;return `<div class="item${on?' on':''}"><div class="i"><b>${t.name}</b><span class="mut">${t.detail}</span><div style="display:flex;gap:4px;margin-top:5px">${t.pal.map(c=>`<i style="width:14px;height:14px;border-radius:50%;background:${c}"></i>`).join('')}</div></div>${o?`<button class="btn${on?' alt':''} sm" data-eqc="${t.id}">${on?'Aktiv':'Wählen'}</button>`:`<button class="btn sm" data-buyi="c_${t.id}" data-price="${t.price}" ${S.coins<t.price?'disabled':''}>${coin}${t.price}</button>`}</div>`}).join('');
 if(ctx.tab==='boosts')b=`<p class="mut">Aktiv: ${S.coinBoost} Spiele Münz-Booster · ${S.xpBoost} Spiele XP-Booster</p>`+M.BOOSTS.map(t=>`<div class="item"><div class="i"><b>${t.name}</b><span class="mut">${t.detail}</span></div><button class="btn sm" data-boost="${t.id}" ${S.coins<t.price?'disabled':''}>${coin}${t.price}</button></div>`).join('');
 return bar('Shop',true,`<span class="pill">${coin}${S.coins}</span>`)+`<div class="body"><div class="tabs">${tabs.map(t=>`<button class="chip" data-tab="${t[0]}" aria-pressed="${ctx.tab===t[0]}">${t[1]}</button>`).join('')}</div>${b}</div>`},

wheel(){const n=M.WHEEL.length,seg=360/n,grad=M.WHEEL.map((p,i)=>`${p.color} ${i*seg}deg ${(i+1)*seg}deg`).join(','),can=canWheel()&&!ctx.spin;
 const lab=M.WHEEL.map((p,i)=>`<span style="transform:rotate(${i*seg+seg/2-90}deg) translate(100px,-11px) rotate(90deg);color:#111">${p.label}<small>${p.sub}</small></span>`).join('');
 return bar('Glücksrad')+`<div class="body"><p class="mut" style="text-align:center">Einmal pro Tag drehen. Dazu gibt es einen Serienbonus von ${Math.min(Math.max(S.streak,1),7)*5} Münzen (${S.streak} Tage in Folge).</p>
 <div class="wheel"><div class="pt"></div><div class="w" id="wh" style="background:conic-gradient(from 0deg,${grad})">${lab}</div></div>
 <div id="wres" style="text-align:center;min-height:30px" class="big"></div>
 <button class="btn" data-a="spin" ${can?'':'disabled'}>${canWheel()?'Drehen':'Morgen wieder'}</button></div>`},

daily(){const tasks=M.todays();
 return bar('Tagesaufgaben')+`<div class="body"><p class="mut">Jeden Tag gibt es neue Aufgaben. Die Belohnung kommt automatisch.</p>${tasks.map(t=>{const p=Math.min(t.prog(S.daily),t.goal),d=S.daily.claimed.includes(t.id);return `<div class="card"><div class="top"><b style="flex:1">${t.title}</b><span class="pill">${d?'✓ ':''}+${t.reward}</span></div><div class="pb" style="margin:8px 0 4px"><i style="width:${p/t.goal*100}%"></i></div><span class="mut">${p} / ${t.goal}</span></div>`}).join('')}
 <button class="btn" data-a="play">Spielen</button></div>`},

ach(){return bar('Erfolge')+`<div class="body"><p class="mut">${S.ach.length} / ${M.ACH.length} freigeschaltet</p>${M.ACH.map(a=>{const d=S.ach.includes(a.id);return `<div class="item${d?' on':''}" style="${d?'':'opacity:.6'}"><span style="font-size:30px">${a.icon}</span><div class="i"><b>${a.title}</b><span class="mut">${a.detail}</span></div><span class="pill">+${a.reward}</span></div>`}).join('')}</div>`},

setup(){const t=ctx.mode==='tour';
 const names=[...Array(ctx.n)].map((_,i)=>`<div><label class="f" for="nm${i}">Spieler ${i+1}</label><div class="top"><button class="ib" data-skin="${i}" aria-label="Skin wechseln" style="flex:none;width:52px;height:52px">${M.bearSVG(skinOf(S.skinIds[i]),38)}</button><input class="t" id="nm${i}" data-name="${i}" maxlength="14" value="${esc(S.names[i])}" autocomplete="off"></div></div>`).join('');
 return bar(t?'Turnier':'Spielen')+`<div class="body">
 <div class="card"><label class="f">Wie viele Spieler?</label><div class="row">${[1,2,3,4].map(n=>`<button class="chip" data-n="${n}" aria-pressed="${ctx.n===n}">${n}</button>`).join('')}</div>
 <p class="mut" style="margin-top:10px">${ctx.n===1?'Du spielst gegen den Computer.':'Alle spielen am selben Gerät. Bei Punktespielen kommt jeder der Reihe nach dran.'}</p></div>
 <div class="card" style="display:grid;gap:12px">${names}<p class="mut">Tippe auf den Bären, um den Skin zu wechseln. Mehr Skins gibt es im Shop.</p></div>
 ${ctx.n===1?`<div class="card"><label class="f">Stärke des Computers</label><div class="row">${LV.map((x,i)=>`<button class="chip" data-d="${i}" aria-pressed="${ctx.diff===i}">${x}</button>`).join('')}</div></div>`:''}
 ${t?`<div class="card"><label class="f">Anzahl Runden</label><div class="row">${[3,5,7,10,15].map(n=>`<button class="chip" data-r="${n}" aria-pressed="${ctx.rounds===n}">${n}</button>`).join('')}</div><p class="mut" style="margin-top:10px">Pro Runde wird ein Spiel ausgelost. Das Finale zählt doppelt.</p></div>`:''}
 <button class="btn" data-a="${t?'tourgo':'pick'}">${t?'Turnier starten':'Weiter'}</button></div>`},

picker(){const ids=Object.keys(G),rest=ALL.filter(a=>!G[a[0]]);
 const tile=(id,ok)=>`<button class="tile${ok?'':' off'}" data-g="${id}" data-ok="${ok?1:0}"><img src="img/games/${id}.jpg" alt="" loading="lazy"><span class="t">${NAME[id]}<small>${ok?G[id]?G[id].sub:'':'Nur in der App'}</small></span></button>`;
 return bar('Spiel wählen')+`<div class="body"><h3 class="sec">Alle Spiele</h3><div class="grid">${ids.map(id=>tile(id,compatible(id,ctx.n))).join('')}</div>
 ${rest.length?`<h3 class="sec" style="margin-top:14px">Nur in der App</h3><div class="grid">${rest.map(a=>tile(a[0],false)).join('')}</div>`:''}</div>`},

intro(){const id=ctx.sess.id,g=G[id],sd=ctx.sess.seats;
 return bar(g.name)+`<div class="body intro"><img src="img/games/${id}.jpg" alt="Spielbild ${g.name}">
 <div class="card"><p>${g.help}</p></div>
 <div class="card"><b>Dabei:</b> ${sd.map(s=>esc(s.name)).join(', ')}<p class="mut" style="margin-top:6px">${g.versus?(ctx.n===2?'Zu zweit am selben Bildschirm: '+esc(sd[0].name)+' spielt unten, '+esc(sd[1].name)+' oben.':'Du spielst unten, der Computer oben.'):(sd.length>1?'Jeder spielt für sich, der Reihe nach. Gib das Gerät weiter, wenn du fertig bist.':'')}</p></div>
 <button class="btn" data-a="start">Start</button></div>`},

game(){const g=G[ctx.sess.id];
 return `<div class="bar"><button class="ib" data-a="pause" aria-label="Pause">❚❚</button><h2>${g.name}</h2></div><div class="stage"><div class="frame" id="frame"></div></div>`},

result(){const r=ctx.res,t=ctx.tour,fin=t&&t.round===t.rounds-1;
 const rows=r.order.map((si,k)=>{const s=r.seats[si],sc=r.scores[si];return `<div class="rank${k===0?' win':''}"><span class="p">${r.pos[k]}</span><span class="nm">${esc(s.name)}</span><span class="sc">${sc==null?(k===0?'Sieg':''):sc+(G[ctx.sess.id].unit||'')}${t?'<br>+'+r.pts[si]+' Pkt':''}</span></div>`}).join('');
 return `<div class="body" style="justify-content:center"><div style="text-align:center"><div class="mut">${G[ctx.sess.id].name}</div><div class="big">${r.tie?'Unentschieden':esc(r.seats[r.order[0]].name)+' gewinnt'}</div>${r.gain?`<div class="mut" style="margin-top:6px">+${r.coins} Münzen · +${r.gain} XP${r.rec?' · Neuer Rekord!':''}</div>`:''}${(r.msgs||[]).map(m=>`<div class="pill" style="margin-top:6px;display:inline-block">${esc(m)}</div>`).join('<br>')}</div>
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
 return bar('Stats')+`<div class="body"><div class="card"><table><tr><td>Gespielte Spiele</td><td>${S.played}</td></tr><tr><td>Siege</td><td>${S.wins}</td></tr><tr><td>Turniere gespielt / gewonnen</td><td>${S.tPlayed} / ${S.tWon}</td></tr><tr><td>Tore</td><td>${S.goals}</td></tr><tr><td>Gefangene Bälle</td><td>${S.balls}</td></tr><tr><td>Getroffene Ziele</td><td>${S.hits}</td></tr><tr><td>Quiz richtig</td><td>${S.quiz}</td></tr><tr><td>Beste Reaktion</td><td>${S.bestReact?S.bestReact+' ms':'–'}</td></tr><tr><td>Verschiedene Spiele</td><td>${S.kinds.length} / ${ALL.length}</td></tr><tr><td>Level</td><td>${lvl().level} · ${M.rank(lvl().level)}</td></tr></table></div>
 <div class="card"><b>Rekorde</b><table style="margin-top:6px">${rows}</table></div></div>`},

settings(){return bar('Einstellungen')+`<div class="body">
 <div class="card"><label class="f">Standard-Stärke des Computers</label><div class="row">${LV.map((x,i)=>`<button class="chip" data-sd="${i}" aria-pressed="${S.diff===i}">${x}</button>`).join('')}</div></div>
 <div class="card"><label class="f">Ton</label><div class="row"><button class="chip" data-snd="1" aria-pressed="${S.sound}">An</button><button class="chip" data-snd="0" aria-pressed="${!S.sound}">Aus</button></div></div>
 <div class="card"><label class="f">Fortschritt</label><p class="mut" style="margin-bottom:10px">Münzen, Skins, Erfolge, Rekorde und Namen liegen nur in deinem Browser. Sie sind nicht mit der App verbunden.</p><button class="btn alt sm" data-a="reset">${ctx.confirmReset?'Wirklich alles löschen?':'Zurücksetzen'}</button></div>
 <div class="card"><a class="lnk" href="datenschutz.html">Datenschutz</a><a class="lnk" href="impressum.html">Impressum</a><a class="lnk" href="index.html">Zur Webseite</a></div>
 <p class="mut" style="text-align:center">Die offizielle Spiele-App von Unihockey am Greifensee Grizzlys, im Browser.</p></div>`}
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
  if(g.versus){GA.skin=skinOf(s.seats[0].skin).color;
    const two=s.seats.length===2&&!s.seats[1].cpu;
    setOv(`<h2>${g.name}</h2><p>${two?esc(s.seats[0].name)+' spielt unten, '+esc(s.seats[1].name)+' oben.':esc(s.seats[0].name)+' spielt unten gegen den Computer ('+LV[ctx.diff]+').'}</p><button class="btn" data-a="go">Los</button>`);
    ctx.run=()=>{setOv('');ctx.inGame=true;R.play(s.id,{skill:SK[ctx.diff],two},res=>finish({winner:res.winner}))};return}
  if(s.turn>=humans.length){
    const cpu=s.seats.findIndex(x=>x.cpu);if(cpu>=0)s.scores[cpu]=g.cpuScore(SK[ctx.diff]);
    finish({scores:s.scores});return}
  const me=humans[s.turn];GA.skin=skinOf(me.skin).color;
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
  // Fortschritt (ein Profil pro Browser, einmal pro Spiel)
  const tie=pos.length>1&&pos[0]===pos[1];let gain=0,rec=false,coins=0;const msgs=[];const winnerHuman=!s.seats[order[0]].cpu&&!tie;
  rollDaily();
  const hs=s.seats.map((st,i)=>i).filter(i=>!s.seats[i].cpu);
  S.played++;S.daily.games++;if(winnerHuman){S.wins++;S.daily.wins++}
  if(!S.kinds.includes(s.id))S.kinds.push(s.id);if(!S.daily.kinds.includes(s.id))S.daily.kinds.push(s.id);
  const best=scores&&scores[hs[0]]!=null?hs.map(i=>scores[i]):[];
  hs.forEach(i=>{if(g.best&&scores[i]!=null){const old=S.rec[s.id],hi=g.best==='hoch';if(old==null||(hi?scores[i]>old:scores[i]<old)){if(!(hi&&scores[i]<=0)){S.rec[s.id]=scores[i];rec=old!=null}}}});
  const top=best.length?Math.max(...best.map(Math.abs)):0;
  ['goals','balls','hits'].forEach(k=>{if(STAT[k].includes(s.id)&&top>0){const v=Math.min(Math.round(top),k==='goals'?8:20);S[k]+=v;if(k==='goals')S.daily.goals+=v;if(k==='balls')S.daily.balls+=v}});
  if(s.id==='quiz'&&top>0){const v=Math.min(6,Math.max(1,Math.round(top/10)));S.quiz+=v;S.daily.quiz+=v}
  if((s.id==='reflex'||s.id==='reaction')&&best.length){const m=Math.min(...best);if(m>0&&m<900&&(!S.bestReact||m<S.bestReact))S.bestReact=m}
  coins=4+(winnerHuman?6:0);if(S.coinBoost>0){coins*=2;S.coinBoost--}addCoins(coins);
  gain=14+(winnerHuman?18:0)+(ctx.tour?6:0);if(S.xpBoost>0){gain*=2;S.xpBoost--}
  msgs.push(...addXP(gain),...checkAch(),...checkDaily());save();
  if(ctx.tour)ctx.tour.points=ctx.tour.points.map((p,i)=>p+pts[i]);
  ctx.res={seats:s.seats,order,pos,scores,pts,gain,coins,rec,winnerHuman,tie,msgs};beep(winnerHuman?660:330,.25);if(winnerHuman&&!tie)setTimeout(confetti,300);
  ctx.inGame=false;replace('result');
}
function pause(){if(!ctx.inGame)return;R.pause();ctx.prevOv=ctx.ov;setOv('<h2>Pause</h2><button class="btn" data-a="resume">Weiterspielen</button><button class="btn alt" data-a="quit">Spiel beenden</button>')}

/* ---------- Eingaben ---------- */
$app.addEventListener('click',e=>{
  const t=e.target.closest('button,a');if(!t||t.tagName==='A')return;
  const d=t.dataset;beep(520,.05,'square');
  if(d.n){ctx.n=+d.n;render('setup');return}
  if(d.skin!=null){const i=+d.skin,own=S.unlocked,k=own.indexOf(S.skinIds[i]);S.skinIds[i]=own[(k+1)%own.length];save();render('setup');return}
  if(d.card!=null){ctx.card=+d.card;render('shop');return}
  if(d.tab){ctx.tab=d.tab;render('shop');return}
  if(d.snd!=null){S.sound=d.snd==='1';save();render('settings');return}
  if(d.buy){const k=skinOf(d.buy);if(S.coins>=k.price&&!S.unlocked.includes(k.id)){S.coins-=k.price;S.unlocked.push(k.id);S.skinIds[ctx.card]=k.id;const m=checkAch();save();toast(m[0]||k.name+' gekauft')}render('shop');return}
  if(d.eq){S.skinIds[ctx.card]=d.eq;save();render('shop');return}
  if(d.buyi){const it=M.TITLES.find(x=>x.id===d.buyi),price=it?it.price:+d.price;if(S.coins>=price&&!S.items.includes(d.buyi)){S.coins-=price;S.items.push(d.buyi);if(it)S.titleId=it.id;else S.cheerId=d.buyi.slice(2);save();toast('Gekauft')}render('shop');return}
  if(d.eqt){S.titleId=d.eqt;save();render('shop');return}
  if(d.eqc){S.cheerId=d.eqc;save();render('shop');return}
  if(d.boost){const b=M.BOOSTS.find(x=>x.id===d.boost);if(S.coins>=b.price){S.coins-=b.price;if(b.id==='coin2')S.coinBoost+=10;else S.xpBoost+=10;save();toast('Booster aktiv')}render('shop');return}
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
   case'shop':ctx.card=0;push('shop');break;
   case'ach':push('ach');break;
   case'daily':push('daily');break;
   case'wheel':ctx.spin=false;push('wheel');break;
   case'random':{const p=gamesFor(ctx.n);ctx.tour=null;ctx.sess={id:p[Math.floor(Math.random()*p.length)],seats:seatsOf()};push('intro');break}
   case'spin':{if(!canWheel()||ctx.spin)break;ctx.spin=true;let r=Math.random()*M.WHEEL.reduce((a,p)=>a+p.weight,0),k=0;for(;k<M.WHEEL.length;k++){if(r<M.WHEEL[k].weight)break;r-=M.WHEEL[k].weight}k=Math.min(k,M.WHEEL.length-1);
     const pz=M.WHEEL[k],bonus=Math.min(Math.max(S.streak,1),7)*5;S.lastWheel=M.key();
     if(pz.kind==='coins')addCoins(pz.amount);else if(pz.kind==='xp')addXP(pz.amount);else S.coinBoost+=pz.amount;addCoins(bonus);const m=checkAch();save();
     const seg=360/M.WHEEL.length,wh=document.getElementById('wh');wh.style.transform='rotate('+(360*6-(k*seg+seg/2))+'deg)';
     document.querySelector('[data-a=spin]').disabled=true;beep(440,.1);
     setTimeout(()=>{const e=document.getElementById('wres');if(e)e.textContent=(pz.kind==='boost'?'Booster x2 (5 Spiele)':pz.label+' '+pz.sub)+' + '+bonus+' Münzen';beep(880,.3);confetti();if(m.length)toast(m[0]);ctx.spin=false},matchMedia('(prefers-reduced-motion:reduce)').matches?100:4300);break}
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
   case'next':{const tr=ctx.tour;tr.round++;if(tr.round>=tr.rounds){S.tPlayed++;const ord=tr.seats.map((_,i)=>i).sort((a,b)=>tr.points[b]-tr.points[a]);if(!tr.seats[ord[0]].cpu&&(ord.length<2||tr.points[ord[0]]>tr.points[ord[1]])){S.tWon++;confetti()}const m=checkAch();save();if(m.length)toast(m[0]);replace('podium')}else{pickRound();replace('tour')}break}
   case'reset':if(ctx.confirmReset){S=defS();rollDaily();ctx.diff=2;save();ctx.confirmReset=false;toast('Fortschritt gelöscht')}else ctx.confirmReset=true;render('settings');break;
  }});
$app.addEventListener('input',e=>{const i=e.target.dataset.name;if(i!=null){S.names[+i]=e.target.value;save()}});
function pickRound(){const t=ctx.tour,pool=Object.keys(G).filter(id=>compatible(id,ctx.n)&&id!==t.last);t.next=pool[Math.floor(Math.random()*pool.length)];t.last=t.next}
window.__app={ctx,S,render};
render('hub');
})();
