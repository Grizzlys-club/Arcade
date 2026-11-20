(()=>{
'use strict';
const ALL=[["penalty","Penalty-Duell","Sport"],["goalie","Torwart-Panik","Sport"],["airhockey","Air-Hockey","Sport"],["puckgolf","Puck-Golf","Sport"],["ballrain","Ballregen","Sport"],["powershot","Power-Schuss","Sport"],["hotpuck","Heisser Puck","Sport"],["sumo","Eis-Sumo","Sport"],["ninja","Puck-Ninja","Sport"],["juggle","Ballhalten","Sport"],["quiz","Unihockey-Quiz","Sport"],["duel","Schläger-Duell","Sport"],["dash","Bären-Sprint","Sport"],["flappy","Flatter-Bär","Party"],["hopper","Bären-Hüpfer","Party"],["stack","Bären-Turm","Party"],["simon","Grizzly Says","Party"],["reaction","Reaktions-Duell","Party"],["numbers","Zahlen-Jagd","Party"],["colors","Farben-Falle","Party"],["balance","Eis-Balance","Party"],["territory","Revierkampf","Party"],["tapsprint","Tap-Sprint","Party"],["whack","Puck-Jagd","Sport"],["memory","Bären-Memory","Party"],["curling","Eis-Curling","Sport"],["slalom","Slalom-Dribbling","Sport"],["pong","Puck-Pong","Sport"],["bowling","Bären-Bowling","Party"],["tugwar","Tauziehen","Party"],["darts","Bären-Darts","Party"],["hoops","Korbjagd","Sport"],["hurdles","Hürdenlauf","Party"],["mathduel","Kopfrechnen","Party"],["rhythm","Takt-Tipper","Party"],["billiard","Puck-Billard","Sport"],["arrows","Pfeil-Panik","Party"],["oddone","Ausreisser","Party"],["compare","Grösser oder kleiner","Party"],["sorter","Farb-Sortierer","Party"],["dodge","Puck-Ausweichen","Sport"],["cave","Höhlenflug","Party"],["pendulum","Pendel-Wurf","Sport"],["count","Puck-Zähler","Party"],["stoptime","Zeit-Stopp","Party"],["slide","Eis-Rutsch","Sport"],["snowball","Schneeballschlacht","Party"],["zigzag","Zickzack-Bär","Party"],["lightsout","Lichter aus","Party"],["reflex","Finger-Blitz","Party"],["shooting","Schiessstand","Sport"],["bank","Bandenschuss","Sport"],["skater","Eis-Läufer","Sport"],["popper","Ballon-Platzer","Party"],["jump","Seilspringen","Party"],["pump","Ballon-Aufpumpen","Party"],["pattern","Muster-Blick","Party"],["target","Summen-Jagd","Party"],["snake","Bären-Snake","Party"],["breakout","Puck-Ausbruch","Sport"]];
const G=window.GAMES,R=window.Runner,M=window.META,AR=window.Arcade;
const UNIT={penalty:'Tore',puckgolf:'Tore',goalie:'Paraden',juggle:'Serie',hopper:'Höhe',stack:'Höhe',flappy:'Tore'};const unitOf=id=>UNIT[id]||'Punkte';
const playable=id=>!!(AR.has(id)||G[id]);
const isNew=id=>AR.has(id);
const GI=id=>({name:NAME[id],help:(window.RULES||{})[id]||'',sub:'ca. '+(window.SECS||{})[id]+' Sekunden',versus:!!(G[id]&&G[id].versus&&!isNew(id))});
const layoutOf=id=>isNew(id)?AR.reg[id].layout:'zones';
const NAME={},TAG={};ALL.forEach(a=>{NAME[a[0]]=a[1];TAG[a[0]]=a[2]});
const DN=['EINSTEIGER','LEICHT','MITTEL','SCHWER','EXTREM'],DC=['#66f299','#40ff73','#ff8a00','#ff6650','#ff4db3'],SK=[.04,.14,.26,.42,.64];
const DB=['Die CPU patzt oft und lässt dir viel Raum. Perfekt zum Üben.','Du hast gute Siegchancen, die CPU macht noch regelmässig Fehler.','Ein faires Duell: Wer konzentriert spielt, gewinnt.','Eine echte Herausforderung. Die CPU reagiert schnell und patzt selten.','Fast unmöglich, aber machbar: Die CPU spielt am Limit. Nur für Profis.'];
const SEAT=['#ff8a00','#40ccff','#40ff73','#ff4db3'],CPUN=['Brummi','Tatze','Honig','Pelzi'];
const $app=document.getElementById('app');
const esc=s=>String(s).replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));

/* Speicher */
const KEY='ga.web.v2';
const defS=()=>({xp:0,played:0,wins:0,diff:2,names:['Spieler 1','Spieler 2','Spieler 3','Spieler 4'],slots:['human','cpu','off','off'],rec:{},coins:0,totalCoins:0,unlocked:['classic','orange','ice','pink'],skinIds:['orange','classic','ice','pink'],ach:[],daily:{date:'',games:0,wins:0,goals:0,balls:0,quiz:0,kinds:[],claimed:[]},streak:0,lastLogin:'',lastWheel:'',items:[],titleId:'rookie',cheerId:'classic',coinBoost:0,xpBoost:0,goals:0,balls:0,quiz:0,hits:0,bestReact:0,tWon:0,tPlayed:0,kinds:[],sound:true,music:true,haptics:true});
let S=defS();
try{const j=JSON.parse(localStorage.getItem(KEY)||localStorage.getItem('ga.web.v1')||'null');if(j)S=Object.assign(S,j)}catch(e){}
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

/* Ton, Musik, Vibration */
let AC=null;const ac=()=>{try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();if(AC.state==='suspended')AC.resume()}catch(e){}return AC};
function beep(f,d,t,v){if(!S.sound)return;try{const a=ac(),o=a.createOscillator(),g=a.createGain();o.type=t||'sine';o.frequency.value=f;g.gain.value=v||.06;o.connect(g);g.connect(a.destination);o.start();g.gain.exponentialRampToValueAtTime(.0001,a.currentTime+d);o.stop(a.currentTime+d)}catch(e){}}
const buzz=n=>{if(S.haptics&&navigator.vibrate)try{navigator.vibrate(n||12)}catch(e){}};
let mus=null;const PENT=[261.6,329.6,392,523.3,392,329.6,440,349.2];let mi=0;
function music(){if(mus){clearInterval(mus);mus=null}if(!S.music)return;mus=setInterval(()=>{if(document.hidden||!AC)return;try{const a=AC,o=a.createOscillator(),g=a.createGain();o.type='triangle';o.frequency.value=PENT[mi++%PENT.length];g.gain.value=.018;o.connect(g);g.connect(a.destination);o.start();g.gain.exponentialRampToValueAtTime(.0001,a.currentTime+.32);o.stop(a.currentTime+.32)}catch(e){}},360)}
async function shareRes(){const r=ctx.res;if(!r)return;const W=1080,H=1350,c=document.createElement('canvas');c.width=W;c.height=H;const x=c.getContext('2d');
 let g=x.createLinearGradient(0,0,W,H);g.addColorStop(0,'#17110a');g.addColorStop(1,'#07050a');x.fillStyle=g;x.fillRect(0,0,W,H);
 g=x.createRadialGradient(W*.85,0,0,W*.85,0,W);g.addColorStop(0,'rgba(217,172,92,.35)');g.addColorStop(1,'rgba(217,172,92,0)');x.fillStyle=g;x.fillRect(0,0,W,H);
 x.strokeStyle='rgba(232,201,138,.5)';x.lineWidth=3;x.strokeRect(40,40,W-80,H-80);
 const gold=x.createLinearGradient(0,0,W,0);gold.addColorStop(0,'#f6e3b4');gold.addColorStop(.5,'#d9ac5c');gold.addColorStop(1,'#9c6f2a');
 x.textAlign='center';x.fillStyle=gold;x.font='italic 120px "Instrument Serif",Georgia,serif';x.fillText('Grizzlys Arcade',W/2,210);
 x.fillStyle='rgba(243,236,224,.6)';x.font='500 34px Inter,sans-serif';x.fillText((NAME[ctx.sess.id]||'').toUpperCase(),W/2,290);
 x.fillStyle='#f3ece0';x.font='96px "Instrument Serif",Georgia,serif';x.fillText(r.tie?'Unentschieden':r.seats[r.order[0]].name+' gewinnt',W/2,470);
 r.order.slice(0,4).forEach((si,k)=>{const y=600+k*140,s=r.seats[si],sc=r.scores[si];x.fillStyle=k===0?'rgba(217,172,92,.18)':'rgba(255,255,255,.05)';x.beginPath();x.roundRect(110,y-70,W-220,110,28);x.fill();if(k===0){x.strokeStyle='rgba(232,201,138,.7)';x.lineWidth=2;x.stroke()}
  x.textAlign='left';x.fillStyle=k===0?'#d9ac5c':'rgba(243,236,224,.5)';x.font='italic 64px "Instrument Serif",Georgia,serif';x.fillText(String(r.pos[k]),150,y+4);x.fillStyle='#f3ece0';x.font='600 44px Inter,sans-serif';x.fillText(String(s.name).slice(0,14),240,y+4);
  x.textAlign='right';x.fillStyle=k===0?'#f6e3b4':'#f3ece0';x.font='600 44px Inter,sans-serif';x.fillText(sc==null?(k===0?'Sieg':''):sc+' '+unitOf(ctx.sess.id),W-150,y+4)});
 x.textAlign='center';x.fillStyle='rgba(243,236,224,.55)';x.font='500 32px Inter,sans-serif';x.fillText('Spiel mit auf grizzlys-club.github.io/Arcade',W/2,H-110);
 const blob=await new Promise(res=>c.toBlob(res,'image/png'));if(!blob)return;const f=new File([blob],'grizzlys-arcade.png',{type:'image/png'});
 try{if(navigator.canShare&&navigator.canShare({files:[f]})){await navigator.share({files:[f],title:'Grizzlys Arcade',text:'Spiel mit! https://grizzlys-club.github.io/Arcade/'});return}}catch(e){if(e&&e.name==='AbortError')return}
 const u=URL.createObjectURL(blob),l=document.createElement('a');l.href=u;l.download='grizzlys-arcade.png';document.body.appendChild(l);l.click();l.remove();setTimeout(()=>URL.revokeObjectURL(u),4000)}
function confetti(){if(matchMedia('(prefers-reduced-motion:reduce)').matches)return;const pal=cheerOf().pal;for(let i=0;i<46;i++){const e=document.createElement('i');e.className='cf';e.style.left=Math.random()*100+'vw';e.style.background=pal[i%pal.length];e.style.animationDelay=Math.random()*.6+'s';document.body.appendChild(e);setTimeout(()=>e.remove(),3400)}}
const STAT={goals:['penalty','powershot','hoops','puckgolf'],balls:['ballrain','goalie','juggle'],hits:['darts','snowball','whack','sorter','ninja']};

/* Zustand */
const ctx={mode:'play',rounds:5,sess:null,tour:null,inGame:false,ov:'',confirmReset:false,tab:'skins',filter:'all',spin:false,cur:'hub'};
const canvas=document.createElement('canvas');canvas.width=360;canvas.height=640;canvas.setAttribute('aria-label','Spielfeld');
R.mount(canvas);
const canvas2=document.createElement('canvas');canvas2.setAttribute('aria-label','Spielfeld');AR.mount(canvas2);ctx.ratio=9/16;
const activeCards=()=>[0,1,2,3].filter(i=>S.slots[i]!=='off');
const seatsOf=()=>activeCards().map(c=>({card:c,cpu:S.slots[c]==='cpu',name:S.slots[c]==='cpu'?CPUN[c]:((S.names[c]||'').trim()||'Spieler '+(c+1)),skin:S.skinIds[c]}));
const nSeats=()=>activeCards().length,nHum=()=>activeCards().filter(c=>S.slots[c]==='human').length;
const compatible=(id,n)=>isNew(id)?(n>=2&&n<=(id==='tugwar'?2:4)):(G[id]&&(!G[id].versus||n===2));
const gamesFor=n=>ALL.map(a=>a[0]).filter(id=>playable(id)&&compatible(id,n));
const featured=()=>{const p=gamesFor(nSeats());return p[M.doy()%p.length]};
const accOf=id=>M.ACC[id]||'#ff8a00';

/* Verlauf */
function push(name){history.pushState({s:name},'','#'+name);render(name)}
function replace(name){history.replaceState({s:name},'','#'+name);render(name)}
history.replaceState({s:'guard'},'','#');history.pushState({s:'hub'},'','#hub');
window.addEventListener('popstate',e=>{
  const s=e.state&&e.state.s;
  if(s==='guard'){history.pushState({s:'hub'},'','#hub');if(ctx.inGame)pause();else render('hub');return}
  if(ctx.inGame){history.pushState({s:'game'},'','#game');pause();return}
  if(!s||!SCREENS[s]||s==='game'||(s==='result'&&!ctx.res)){render('hub');return}
  render(s)});
function toast(t){let el=document.getElementById('toast');if(!el){el=document.createElement('div');el.id='toast';document.body.appendChild(el)}
  el.textContent=t;el.style.display='block';clearTimeout(toast.t);toast.t=setTimeout(()=>el.style.display='none',2400)}

/* Bausteine */
const coin=(c)=>`<span class="coin${c||''}"></span>`;
const coinPill=()=>`<span class="coinp">${coin()}${S.coins}</span>`;
const bar=(title,back=true,right='')=>`<div class="bar">${back?'<button class="ib" data-a="back" aria-label="Zurück">‹</button>':''}<h2>${title}</h2>${right}</div>`;
const bimg=(id,h,flip)=>{const u=M.bearURL(skinOf(id),h);return u?`<img class="bear" src="${u}" height="${Math.round(h*1.18)}" alt="" style="${flip?'transform:scaleX(-1)':''}">`:`<div style="height:${h}px"></div>`};
const IC={shop:'<svg viewBox="0 0 24 24"><path d="M5 8h14l-1 12H6z"/><path d="M9 8a3 3 0 016 0"/></svg>',stats:'<svg viewBox="0 0 24 24"><path d="M5 20V11M12 20V4M19 20v-7"/></svg>',ach:'<svg viewBox="0 0 24 24"><circle cx="12" cy="9" r="5"/><path d="M8.5 13.5L7 21l5-3 5 3-1.5-7.5"/></svg>',gift:'<svg viewBox="0 0 24 24"><rect x="3" y="9" width="18" height="12" rx="2"/><path d="M12 9v12M3 13h18M12 9C9 9 8 4 11 4c2 0 1 5 1 5zm0 0c3 0 4-5 1-5-2 0-1 5-1 5z"/></svg>',user:'<svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/></svg>',cpu:'<svg viewBox="0 0 24 24"><rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"/></svg>',x:'<svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>'};
const GICO='<svg viewBox="0 0 24 24" width="26" height="26" fill="currentColor"><path d="M7 8h10a4 4 0 014 4v3a2 2 0 01-3.5 1.3L15 14H9l-2.5 2.3A2 2 0 013 15v-3a4 4 0 014-4zm1 2v1H7v1h1v1h1v-1h1v-1H9v-1zm8 .5a1 1 0 100 2 1 1 0 000-2z"/></svg>';
const TRO='<svg viewBox="0 0 24 24" width="26" height="26" fill="currentColor"><path d="M7 3h10v4a5 5 0 01-4 4.9V15h3v2h-8v-2h3v-3.1A5 5 0 017 7zM5 4h2v3H5a1 1 0 000 0zm12 0h2v2a3 3 0 01-2 2.8z"/></svg>';
function sheetBack(){history.back()}

/* ---------- Bildschirme ---------- */
const SCREENS={
hub(){const L=lvl(),p=Math.round(L.into/L.need*100),tasks=M.todays(),done=tasks.filter(t=>S.daily.claimed.includes(t.id)).length,f=featured(),ss=seatsOf();
 const next=tasks.find(t=>!S.daily.claimed.includes(t.id));
 return `<div class="body" style="gap:12px;padding-top:max(12px,env(safe-area-inset-top))">
 <div class="row" style="align-items:center"><button class="ib" data-a="settings" aria-label="Einstellungen" style="font-size:20px">⚙</button>
 <div class="lv"><span class="n">${L.level}</span><div><small>${M.rank(L.level)}</small><div class="xp"><i style="width:${p}%"></i></div></div></div>
 <span class="pill" style="border-color:rgba(255,138,0,.5)">🔥 ${S.streak}</span><span style="flex:1"></span>${coinPill()}</div>
 <img class="logo" src="img/logo.png" alt="Logo Unihockey am Greifensee Grizzlys">
 <div><div class="t1">GRIZZLYS</div><div class="t2">ARCADE</div></div>
 <button class="strip" data-a="setup" aria-label="Spieler ändern">${ss.map(s=>`<div class="p">${bimg(s.skin,40,true)}<span style="color:${SEAT[s.card]}">${esc(s.name)}</span></div>`).join('')}<div class="p" style="color:var(--or)"><div style="font-size:20px">👥</div><span>ÄNDERN</span></div></button>
 <button class="feat" style="--c:rgba(255,138,0,.6)" data-g="${f}" data-ok="1"><img src="img/games/${f}.jpg" alt=""><div style="min-width:0"><small>Spiel des Tages</small><b>${NAME[f]}</b></div><span class="go">▶</span></button>
 <button class="btn" data-a="tour" style="min-height:62px">${TRO} Turnier</button>
 <div class="row"><button class="btn blue" data-a="picker" style="flex:1;min-height:54px;font-size:17px;white-space:nowrap;padding:0 8px">${ALL.length} Spiele</button><button class="btn green" data-a="random" style="flex:1;min-height:54px;font-size:17px;padding:0 8px"><svg viewBox="0 0 24 24" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-.12em"><rect x="4" y="4" width="16" height="16" rx="4"/><circle cx="9" cy="9" r="1" fill="currentColor"/><circle cx="15" cy="15" r="1" fill="currentColor"/><circle cx="12" cy="12" r="1" fill="currentColor"/></svg> Zufall</button></div>
 <div class="row"><button class="mini" style="--c:#ff4db3" data-a="shop">${IC.shop}Shop</button><button class="mini" style="--c:#40ccff" data-a="stats">${IC.stats}Stats</button><button class="mini" style="--c:#ffd61a" data-a="ach">${IC.ach}Erfolge</button><button class="mini" style="--c:#40ff73" data-a="wheel">${IC.gift}Bonus${canWheel()?'<i class="dot"></i>':''}</button></div>
 <button class="strip" style="border-radius:14px;padding:11px 14px;font-weight:800;justify-content:space-between" data-a="ach"><span class="mut" style="font-weight:800"><svg viewBox="0 0 24 24" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" style="vertical-align:-.12em"><path d="M9 6h11M9 12h11M9 18h11M4 6h.01M4 12h.01M4 18h.01"/></svg> Tagesaufgaben ${done}/${tasks.length}</span><span style="color:var(--or);font-weight:900;font-size:13px">${next?next.title:'Alles geschafft'}</span></button>
 </div>`},

setup(){const ss=activeCards();
 const card=c=>{const m=S.slots[c],col=m==='off'?'rgba(255,255,255,.2)':SEAT[c];
  return `<div class="pc${m==='off'?' off':''}" style="--c:${col}">${bimg(S.skinIds[c],70,false)}${m!=='off'?`<button class="cyc" data-skin="${c}" aria-label="Skin wechseln">⟳</button>`:''}
  ${m==='human'?`<input id="nm${c}" data-name="${c}" maxlength="12" value="${esc(S.names[c])}" aria-label="Name Spieler ${c+1}" autocomplete="off">`:`<div class="nm">${m==='cpu'?CPUN[c]+' (CPU)':'–'}</div>`}
  <div class="modes" style="--c:${SEAT[c]}"><button data-slot="${c}:human" aria-pressed="${m==='human'}" aria-label="Mensch">${IC.user}</button><button data-slot="${c}:cpu" aria-pressed="${m==='cpu'}" aria-label="CPU">${IC.cpu}</button><button data-slot="${c}:off" aria-pressed="${m==='off'}" aria-label="Aus">${IC.x}</button></div></div>`};
 const d=S.diff;
 return bar('SPIELER',true)+`<div class="body"><p class="mut" style="text-align:center">Bis zu 4 Spieler an einem Handy. Gib das Handy nach jedem Zug weiter. Bei Duell-Spielen sitzen zwei gegenüber.</p>
 <div class="grid2">${[0,1,2,3].map(card).join('')}</div>
 <div class="card" style="--c:rgba(255,138,0,.5)"><div class="lab" style="color:var(--or)">So sitzt ihr</div><p class="mut" style="margin-top:6px">${ss.length<=2?'Einer unten, einer oben (gegenüber).':'Bei Punktespielen kommt jeder der Reihe nach dran.'} Duell-Spiele wie Air-Hockey gehen zu zweit: unten und oben.</p></div>
 <div class="card" style="--c:rgba(64,204,255,.6)"><div class="row" style="justify-content:space-between"><span class="lab">CPU-Stärke</span><b style="color:${DC[d]};font-size:15px">${DN[d]}</b></div>
 <div class="diff" style="margin-top:10px">${[0,1,2,3,4].map(i=>`<button data-d="${i}" aria-pressed="${d===i}" style="--c:${DC[i]}"><i>${[0,1,2,3,4].map(j=>`<s class="${j<=i?'on':''}" style="height:${8+j*3}px"></s>`).join('')}</i>${i+1}</button>`).join('')}</div><p class="mut" style="margin-top:10px;font-size:12px">${DB[d]}</p></div></div>
 <div class="foot"><button class="btn" data-a="back" ${ss.length<2?'disabled':''}>✓ Fertig</button></div>`},

picker(){const n=nSeats(),f=ctx.filter,list=ALL.filter(a=>playable(a[0])&&(f==='all'||(f==='sport'&&a[2]==='Sport')||(f==='party'&&a[2]==='Party'))),rest=ALL.filter(a=>!playable(a[0]));
 const tile=(id,ok)=>{const c=accOf(id),g=GI(id);return `<button class="tile${ok?'':' dis'}" style="--c:${c}" data-g="${id}" data-ok="${ok?1:0}"><img src="img/games/${id}.jpg" alt="" loading="lazy"><span class="t"><b>${NAME[id]}</b><span class="m"><span>${TAG[id]==='Sport'?'Unihockey':'Party'}</span><span>${(window.SECS||{})[id]||''}s</span></span></span></button>`};
 return bar('SPIELE',true,coinPill())+`<div class="body"><div class="chips">${[['all','Alle '+ALL.length],['sport','Unihockey'],['party','Party']].map(x=>`<button class="chip" style="--cc:#ff8a00" data-f="${x[0]}" aria-pressed="${f===x[0]}">${x[1]}</button>`).join('')}</div>
 <div class="grid2">${list.map(a=>tile(a[0],compatible(a[0],n))).join('')}</div>
 ${rest.length&&f==='all'?`<div class="lab" style="margin-top:6px">Nur in der App</div><div class="grid2">${rest.map(a=>tile(a[0],false)).join('')}</div>`:''}
 <p class="mut" style="text-align:center">${n} Spieler · ${nHum()} Mensch${nHum()===1?'':'en'}</p></div>`},

intro(){const id=ctx.sess.id,g=GI(id),sd=ctx.sess.seats,c=accOf(id),t=ctx.tour,n=sd.length,lay=layoutOf(id);
 const hint=lay==='turns'?'Ihr spielt der Reihe nach auf dem ganzen Bildschirm. Gib das Handy weiter, wenn du fertig bist.':lay==='arena'?(n>=3?'Gemeinsames Spielfeld: Jeder steuert von seiner Handy-Kante aus (unten, oben, links, rechts).':'Gemeinsames Spielfeld: einer unten, einer oben.'):(n>=3?'Jeder hat sein eigenes Viertel des Bildschirms.':'Jeder hat seine eigene Bildschirmhälfte: einer unten, einer oben.');
 return `<div class="bar"><button class="ib" data-a="back" aria-label="Zurück" style="width:auto;border-radius:99px;padding:0 14px;font-size:15px;height:40px">‹ ZURÜCK</button></div><div class="body">
 <div class="card" style="--c:${c};padding:6px;overflow:hidden"><img src="img/games/${id}.jpg" alt="Spielbild ${g.name}" style="width:100%;border-radius:12px;display:block;aspect-ratio:16/10;object-fit:cover;object-position:top"><div style="text-align:center;padding:10px 4px 6px"><b style="font-size:26px;text-transform:uppercase;letter-spacing:.02em">${g.name}</b></div></div>
 <div class="lab" style="text-align:center;color:${c}">${TAG[id]==='Sport'?'Unihockey':'Party'} · ${g.sub.replace('Sekunden','Sek.').toUpperCase()} · ${id==='tugwar'?'2':'2-4'} Spieler</div>
 <div class="card" style="--c:${c}"><div class="lab" style="color:var(--yel)">💡 So geht's</div><p style="font-size:17px;margin-top:6px;font-weight:700">${g.help}</p>${isNew(id)?'<p class="mut" style="margin-top:8px">'+hint+'</p>':g.versus?'<p class="mut" style="margin-top:8px">'+(sd.every(s=>!s.cpu)?esc(sd[0].name)+' spielt unten, '+esc(sd[1].name)+' oben.':'Du spielst unten, die CPU oben.')+'</p>':sd.length>1?'<p class="mut" style="margin-top:8px">Jeder spielt für sich, der Reihe nach. Gib das Handy weiter, wenn du fertig bist.</p>':''}</div>
 <div class="strip" style="cursor:default">${sd.map(s=>`<div class="p">${bimg(s.skin,40,true)}<span style="color:${SEAT[s.card]}">${esc(s.name)}</span>${s.cpu?'<span class="mut" style="font-size:9px">CPU</span>':''}</div>`).join('')}</div></div>
 <div class="foot"><button class="btn" data-a="start">▶ Los geht's</button></div>`},

game(){const g=GI(ctx.sess.id);
 return `<div class="bar" style="padding-bottom:6px"><button class="ib" data-a="pause" aria-label="Pause" style="font-size:15px">❚❚</button><h2 style="font-size:20px">${g.name}</h2></div><div class="stage"><div class="frame" id="frame"></div></div>`},

result(){const r=ctx.res,t=ctx.tour,fin=t&&t.round===t.rounds-1;
 const rows=r.order.map((si,k)=>{const s=r.seats[si],sc=r.scores[si];return `<div class="rank${k===0?' win':''}"><span class="p">${r.pos[k]}</span>${bimg(s.skin,34,true)}<span class="nm" style="color:${SEAT[s.card]}">${esc(s.name)}</span><span class="sc">${sc==null?(k===0?'Sieg':''):sc+' '+unitOf(ctx.sess.id)}${t?'<br>+'+r.pts[si]+' Pkt':''}</span></div>`}).join('');
 return `<div class="body" style="justify-content:center"><div style="text-align:center"><div class="lab">${NAME[ctx.sess.id]}</div><div class="big" style="margin-top:6px">${r.tie?'Unentschieden':esc(r.seats[r.order[0]].name)+' gewinnt'}</div>${r.gain?`<div class="mut" style="margin-top:10px">+${r.coins} ${coin(' s')} · +${r.gain} XP${r.rec?' · Neuer Rekord!':''}</div>`:''}${(r.msgs||[]).map(m=>`<div class="pill" style="margin-top:6px">${esc(m)}</div>`).join('<br>')}</div>
 <div style="display:grid;gap:10px">${rows}</div>
 ${t?`<button class="btn" data-a="next">${fin?'Zur Siegerehrung':'Nächste Runde'}</button>`:`<button class="btn" data-a="again">↻ Nochmal</button><button class="btn blue sm" data-a="picker2">Anderes Spiel</button><button class="btn alt sm" data-a="share">↗ Ergebnis teilen</button><button class="btn alt sm" data-a="home">Hauptmenü</button>`}</div>`},

tsetup(){const ss=seatsOf(),n=ss.length,r=ctx.rounds,tb=n===2?'Sieg 3 · Niederlage 0 · Unentschieden je 1':n===3?'Platz 1: 4 · Platz 2: 2 · Platz 3: 0 Punkte':'Platz 1: 5 · Platz 2: 3 · Platz 3: 1 · Platz 4: 0 Punkte';
 return bar('TURNIER',true,coinPill())+`<div class="body"><div style="text-align:center;color:#ffd61a;filter:drop-shadow(0 0 16px rgba(255,214,26,.5))"><svg viewBox="0 0 24 24" width="84" height="84" fill="currentColor"><path d="M7 3h10v4a5 5 0 01-4 4.9V15h3v2h-8v-2h3v-3.1A5 5 0 017 7zM5 4h2v3H5a1 1 0 000 0zm12 0h2v2a3 3 0 01-2 2.8z"/></svg></div>
 <p style="text-align:center;font-weight:700;color:rgba(255,255,255,.85)">Jede Runde lost die Glücksmaschine ein zufälliges Spiel aus. Wer am Ende die meisten Punkte hat, steht ganz oben auf dem Podest.</p>
 <div class="card" style="--c:rgba(255,138,0,.6)"><div class="lab">Wie viele Runden?</div><div class="chips" style="margin:10px 0 8px">${[3,5,7,10,15].map(x=>`<button class="chip" style="--cc:#ff8a00" data-r="${x}" aria-pressed="${r===x}">${x}</button>`).join('')}</div><span class="mut" style="font-size:12px">ca. ${r+Math.floor(r/2)}–${r*2} Minuten</span></div>
 <div class="card" style="--c:rgba(64,204,255,.6)"><div class="lab">Punkte pro Spiel</div><p style="margin-top:6px;font-weight:700">${tb}</p><p style="color:var(--yel);font-weight:900;margin-top:6px">Das Finale zählt doppelt!</p></div>
 <button class="strip" data-a="setup">${ss.map(s=>`<div class="p">${bimg(s.skin,36,true)}<span style="color:${SEAT[s.card]}">${esc(s.name)}</span></div>`).join('')}<span style="color:var(--or);font-size:22px">✎</span></button></div>
 <div class="foot"><button class="btn" data-a="tourgo" ${n<2?'disabled':''}><svg viewBox="0 0 24 24" width="1em" height="1em" fill="currentColor" style="vertical-align:-.1em"><path d="M12 2l2.2 7.3L22 12l-7.8 2.7L12 22l-2.2-7.3L2 12l7.8-2.7z"/></svg> Turnier starten</button></div>`},

tour(){const t=ctx.tour,fin=t.round===t.rounds-1,ord=t.seats.map((_,i)=>i).sort((a,b)=>t.points[b]-t.points[a]);
 return bar('Runde '+(t.round+1)+' / '+t.rounds,true)+`<div class="body">
 <div class="card" style="--c:${accOf(t.next)};text-align:center"><div class="lab" style="color:var(--or)">${fin?'Finale · zählt doppelt':'Die Glücksmaschine lost aus …'}</div><div class="big" style="font-size:36px;margin-top:8px">${NAME[t.next]}</div></div>
 <div class="card" style="--c:${accOf(t.next)};padding:6px"><img src="img/games/${t.next}.jpg" alt="" style="width:100%;border-radius:12px;display:block;aspect-ratio:16/10;object-fit:cover;object-position:top"></div>
 <div style="display:grid;gap:8px">${ord.map((i,k)=>`<div class="rank"><span class="p">${k+1}</span>${bimg(t.seats[i].skin,32,true)}<span class="nm" style="color:${SEAT[t.seats[i].card]}">${esc(t.seats[i].name)}</span><span class="sc" style="color:#fff;font-size:22px">${t.points[i]}</span></div>`).join('')}</div></div>
 <div class="foot"><button class="btn" data-a="tourplay">▶ Spielen</button></div>`},

podium(){const t=ctx.tour,ord=t.seats.map((_,i)=>i).sort((a,b)=>t.points[b]-t.points[a]);
 const top=ord.slice(0,3),h=[140,180,110];const visual=top.length===1?[0]:top.length===2?[1,0]:[1,0,2];
 const pod=visual.map(k=>`<div class="${k===0?'w':''}" style="height:${h[k]||90}px">${bimg(t.seats[top[k]].skin,k===0?52:42,true)}<b>${k+1}</b>${esc(t.seats[top[k]].name)}<span class="mut">${t.points[top[k]]} Pkt</span></div>`).join('');
 const rest=ord.slice(3).map(i=>`<div class="rank"><span class="p">4.</span><span class="nm">${esc(t.seats[i].name)}</span><span class="sc">${t.points[i]} Pkt</span></div>`).join('');
 return `<div class="body" style="justify-content:center"><div style="text-align:center"><div class="lab" style="color:var(--or);letter-spacing:.3em">Siegerehrung</div><div style="font-size:60px;margin-top:6px;color:#e0b45f;filter:drop-shadow(0 0 18px rgba(224,180,95,.5))"><svg viewBox="0 0 24 24" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-.12em"><path d="M7 4h10v5a5 5 0 0 1-10 0z"/><path d="M7 6H4v1a3 3 0 0 0 3 3M17 6h3v1a3 3 0 0 1-3 3M12 14v4M8 21h8M9 18h6"/></svg></div><div class="big" style="font-size:44px">${esc(t.seats[ord[0]].name)}</div></div>
 <div class="pod">${pod}</div>${rest}<button class="btn" data-a="tour">Neues Turnier</button><button class="btn alt sm" data-a="home">Hauptmenü</button></div>`},

shop(){const tabs=[['skins','Skins','#ff4db3'],['titles','Titel','#ff8a00'],['cheers','Jubel','#ff8a00'],['boosts','Booster','#ff8a00']],own=id=>S.unlocked.includes(id);let b='';
 if(ctx.tab==='skins')b=`<div class="grid2">${M.SKINS.map(k=>{const o=own(k.id),eq=[0,1,2,3].filter(c=>S.skinIds[c]===k.id&&S.slots[c]!=='off');return `<div class="sk${eq.length?' on':''}">${bimg(k.id,86,false)}<b>${k.name}</b><span class="mut" style="font-size:11px">Trikot Nr. ${k.num}</span>${o?`<div class="n">${[0,1,2,3].map(c=>`<button data-eq="${k.id}:${c}" aria-pressed="${S.skinIds[c]===k.id}" style="--c:${SEAT[c]}" aria-label="Für Spieler ${c+1}">${c+1}</button>`).join('')}</div>`:`<button class="price" data-buy="${k.id}" ${S.coins<k.price?'disabled':''}>${k.price} ${coin(' s')}</button>`}</div>`}).join('')}</div>`;
 if(ctx.tab==='titles')b=M.TITLES.map(t=>{const o=t.price===0||S.items.includes(t.id),on=S.titleId===t.id;return `<div class="it${on?' on':''}"><div class="i"><b>${t.name}</b><span class="mut">${t.detail}</span></div>${o?`<button class="btn sm${on?' alt':''}" data-eqt="${t.id}">${on?'Aktiv':'Wählen'}</button>`:`<button class="btn sm" data-buyi="${t.id}" ${S.coins<t.price?'disabled':''}>${t.price} ${coin(' s')}</button>`}</div>`}).join('');
 if(ctx.tab==='cheers')b=M.CHEERS.map(t=>{const o=t.price===0||S.items.includes('c_'+t.id),on=S.cheerId===t.id;return `<div class="it${on?' on':''}"><div class="i"><b>${t.name}</b><span class="mut">${t.detail}</span><div style="display:flex;gap:4px;margin-top:5px">${t.pal.map(c=>`<i style="width:14px;height:14px;border-radius:50%;background:${c}"></i>`).join('')}</div></div>${o?`<button class="btn sm${on?' alt':''}" data-eqc="${t.id}">${on?'Aktiv':'Wählen'}</button>`:`<button class="btn sm" data-buyi="c_${t.id}" data-price="${t.price}" ${S.coins<t.price?'disabled':''}>${t.price} ${coin(' s')}</button>`}</div>`}).join('');
 if(ctx.tab==='boosts')b=`<p class="mut">Aktiv: ${S.coinBoost} Spiele Münz-Booster · ${S.xpBoost} Spiele XP-Booster</p>`+M.BOOSTS.map(t=>`<div class="it"><div class="i"><b>${t.name}</b><span class="mut">${t.detail}</span></div><button class="btn sm" data-boost="${t.id}" ${S.coins<t.price?'disabled':''}>${t.price} ${coin(' s')}</button></div>`).join('');
 return bar('BÄREN-SHOP',true,coinPill())+`<div class="body"><p class="mut" style="text-align:center">Münzen gibt es nur durch Spielen: Spiele, Siege, Erfolge und Tagesaufgaben. Kein Echtgeld.</p><div class="chips">${tabs.map(t=>`<button class="chip" style="--cc:${t[2]}" data-tab="${t[0]}" aria-pressed="${ctx.tab===t[0]}">${t[1]}</button>`).join('')}</div>${b}</div>`},

stats(){const st=[['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="7" width="18" height="11" rx="5"/><path d="M8 10v5M5.5 12.5h5"/><circle cx="16" cy="11.5" r=".8"/><circle cx="18" cy="14" r=".8"/></svg>',S.played,'Spiele'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="14" r="6"/><path d="M8.5 3l3.5 6 3.5-6M12 11.5v5"/></svg>',S.wins,'Siege'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4h10v5a5 5 0 0 1-10 0z"/><path d="M7 6H4v1a3 3 0 0 0 3 3M17 6h3v1a3 3 0 0 1-3 3M12 14v4M8 21h8"/></svg>',S.tWon,'Turniersiege'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.2"/></svg>',S.goals,'Tore'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M9 4a3 3 0 0 0-3 3 3 3 0 0 0-2 5 3 3 0 0 0 2 5 3 3 0 0 0 6 1V4a3 3 0 0 0-3 0zM15 4a3 3 0 0 1 3 3 3 3 0 0 1 2 5 3 3 0 0 1-2 5 3 3 0 0 1-6 1"/></svg>',S.quiz,'Quiz richtig'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M7 21v-6l-3-4 2-2 2 2V5a1.5 1.5 0 0 1 3 0v5l1-5a1.5 1.5 0 0 1 3 .5L15 11l2-1a1.5 1.5 0 0 1 2 2l-3 9z"/></svg>',S.balls,'Bälle'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/></svg>',S.hits,'Treffer'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2L4 14h7l-1 8 9-12h-7z"/></svg>',S.bestReact?S.bestReact+' ms':'-','Reaktion'],['<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="url(#gg)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l2.2 7.3L22 12l-7.8 2.7L12 22l-2.2-7.3L2 12l7.8-2.7z"/></svg>',S.kinds.length+'/'+ALL.length,'Spiele entdeckt']];
 return bar('STATISTIK',true,coinPill())+`<div class="body"><div class="g3">${st.map(x=>`<div class="stat"><span class="ic">${x[0]}</span><b>${x[1]}</b><span>${x[2]}</span></div>`).join('')}</div>
 <div class="card" style="--c:rgba(255,138,0,.5)"><div class="lab" style="color:var(--or)">Rekorde</div>${ALL.map(a=>{const id=a[0],r=S.rec[id];return `<div class="rec"><i style="background:${accOf(id)}"></i>${a[1]}<span class="${r==null?'z':''}">${r==null?'–':r+' '+unitOf(id)}</span></div>`}).join('')}</div></div>`},

ach(){const tasks=M.todays();
 return bar('ERFOLGE',true,coinPill())+`<div class="body"><div class="card" style="--c:rgba(255,138,0,.6)"><div class="lab" style="color:var(--or)">Heute</div>${tasks.map(t=>{const p=Math.min(t.prog(S.daily),t.goal);return `<div style="margin-top:12px"><div class="row" style="justify-content:space-between"><b>${t.title}</b><span class="rew">${S.daily.claimed.includes(t.id)?'✓ ':''}+${t.reward} ${coin(' s')}</span></div><div class="pb" style="margin:6px 0 3px"><i style="width:${p/t.goal*100}%"></i></div><span class="mut" style="font-size:11px">${p}/${t.goal}</span></div>`}).join('')}<p class="mut" style="margin-top:10px;font-size:12px">Jeden Tag gibt es neue Aufgaben.</p></div>
 <div class="lab" style="text-align:center">${S.ach.length} / ${M.ACH.length} Erfolge</div>
 ${M.ACH.map(a=>{const d=S.ach.includes(a.id);return `<div class="it${d?' on':' lock'}"><span class="ic">${a.icon}</span><div class="i"><b>${a.title}</b><span class="mut">${a.detail}</span></div><span class="rew">+${a.reward} ${coin(' s')}</span></div>`}).join('')}</div>`},

settings(){const tg=(k,l,i)=>`<div class="trow"><span style="width:24px;text-align:center">${i}</span><span style="flex:1">${l}</span><button class="tg" role="switch" aria-checked="${S[k]}" aria-label="${l}" data-tg="${k}"></button></div>`;
 return bar('EINSTELLUNGEN',true)+`<div class="body"><div class="card" style="--c:rgba(255,138,0,.5)">${tg('sound','Soundeffekte','🔊')}${tg('music','Musik','♪')}${tg('haptics','Vibration','📳')}</div>
 <button class="lrow" data-a="setup">👥 Spieler, Namen & CPU-Stärke<span>›</span></button><a class="lrow" href="datenschutz.html" style="text-decoration:none;color:#fff">🛡 Datenschutz<span>›</span></a><a class="lrow" href="impressum.html" style="text-decoration:none;color:#fff;border-color:var(--line)">Impressum<span>›</span></a>
 <div class="card" style="--c:var(--line);text-align:center"><img src="img/logo.png" alt="" style="width:70px;height:70px;border-radius:50%"><div style="font-weight:900;font-size:19px;margin-top:6px">Grizzlys Arcade</div><p class="mut" style="margin-top:4px">Die offizielle Spiele-App von Unihockey am Greifensee Grizzlys.</p><p class="mut" style="font-size:11px;margin-top:8px">Browser-Version · Keine Werbung · Keine Echtgeld-Käufe · Kein Tracking</p></div>
 <p class="mut" style="text-align:center;font-size:12px">Münzen, Skins, Erfolge, Rekorde und Namen liegen nur in deinem Browser. Sie sind nicht mit der iPhone-App verbunden.</p>
 <button class="btn red" data-a="reset">${ctx.confirmReset?'Wirklich alles löschen?':'Fortschritt zurücksetzen'}</button><a class="lnk" href="index.html">Zur Webseite</a></div>`},

wheel(){const W=M.WHEEL,n=W.length,seg=360/n,can=canWheel()&&!ctx.spin,bonus=Math.min(Math.max(S.streak,1),7)*5,C=200,R=176,pol=(r,d)=>{const t=(d-90)*Math.PI/180;return[C+r*Math.cos(t),C+r*Math.sin(t)]};
 const fills={coins:'#1b1510',xp:'#141b24',boost:'#3a1d0b'};
 const paths=W.map((p,k)=>{const [x1,y1]=pol(R,k*seg),[x2,y2]=pol(R,(k+1)*seg),top=p.label==='100'||p.kind==='boost',fill=top?'url(#gld)':(k%2?fills[p.kind]:'#0f0c09'),tc=top?'#1a1006':'#f3ece0',[lx,ly]=pol(R*.7,k*seg+seg/2);
  return `<path d="M${C} ${C}L${x1} ${y1}A${R} ${R} 0 0 1 ${x2} ${y2}Z" fill="${fill}" stroke="rgba(232,201,138,.55)" stroke-width="1.4"/><g transform="translate(${lx} ${ly}) rotate(${k*seg+seg/2})"><text text-anchor="middle" y="4" font-family="Instrument Serif,Georgia,serif" font-size="${p.label.length>2?30:36}" fill="${tc}">${p.label}</text><text text-anchor="middle" y="24" font-family="Inter,sans-serif" font-size="10" font-weight="600" letter-spacing="1.5" fill="${top?'#3a2308':'rgba(243,236,224,.6)'}">${p.sub.toUpperCase()}</text></g>`}).join('');
 const studs=Array.from({length:24},(_,k)=>{const [x,y]=pol(190,k*15);return `<circle class="stud" style="animation-delay:${(k%2)*.5}s" cx="${x}" cy="${y}" r="3.2"/>`}).join('');
 return SCREENS.hub()+`<div class="ovl"><div class="row" style="align-items:center"><h2 style="font-size:36px;flex:1;font-style:italic;background:linear-gradient(120deg,#f6e3b4,#d9ac5c 50%,#9c6f2a);-webkit-background-clip:text;background-clip:text;color:transparent">Glücksrad</h2><button class="ib" data-a="back" aria-label="Schliessen">✕</button></div>
 <p style="text-align:center;font-weight:600;color:var(--mut)">🔥 Tages-Streak ${S.streak} · Bonus +${bonus} Münzen</p>
 <div class="wheel"><div class="pt"></div><div class="w" id="wh"><svg viewBox="0 0 400 400" width="100%" height="100%"><defs><linearGradient id="gld" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f6e3b4"/><stop offset=".5" stop-color="#d9ac5c"/><stop offset="1" stop-color="#9c6f2a"/></linearGradient><radialGradient id="rim" cx=".5" cy=".5" r=".5"><stop offset=".9" stop-color="#9c6f2a"/><stop offset=".96" stop-color="#f6e3b4"/><stop offset="1" stop-color="#7a5320"/></radialGradient></defs><circle cx="200" cy="200" r="199" fill="url(#rim)"/><circle cx="200" cy="200" r="180" fill="#0a0807"/>${paths}<circle cx="200" cy="200" r="${R}" fill="none" stroke="url(#gld)" stroke-width="3"/>${studs}</svg></div><div class="hubi"></div></div>
 <div id="wres" class="big" style="font-size:34px;text-align:center;min-height:42px"></div>
 <button class="btn" data-a="spin" ${can?'':'disabled'} style="margin-top:auto">${canWheel()?'Drehen':'Morgen wieder'}</button></div>`}
};

function render(name){
  ctx.cur=name;
  if(name!=='game'){ctx.inGame=false;R.stop();AR.stop()}
  const prev=ctx.lastScr;ctx.lastScr=name;
  $app.innerHTML=SCREENS[name]();
  $app.classList.toggle('enter',prev!==name&&name!=='game');
  if(name==='game'){const nw=isNew(ctx.sess.id);ctx.ratio=nw?390/844:9/16;document.getElementById('frame').appendChild(nw?canvas2:canvas);const ov=document.createElement('div');ov.className='ov';ov.id='ov';ov.hidden=true;document.getElementById('frame').appendChild(ov);if(ctx.ov)setOv(ctx.ov);fit()}
  const b=$app.querySelector('.body');if(b)b.scrollTop=0;
}
M.onbear=()=>{if(ctx.cur!=='game')render(ctx.cur)};
if(M.bearCanvas(M.SKINS[1],10))M.onbear=()=>{};
function fit(){const st=document.querySelector('.stage'),fr=document.getElementById('frame');if(!st||!fr)return;let h=st.clientHeight-10-parseFloat(getComputedStyle(st).paddingBottom||0),w=h*(ctx.ratio||9/16);if(w>st.clientWidth-20){w=st.clientWidth-20;h=w/(ctx.ratio||9/16)}fr.style.width=Math.floor(w)+'px';fr.style.height=Math.floor(h)+'px'}
window.addEventListener('resize',fit);
function setOv(html){ctx.ov=html;const ov=document.getElementById('ov');if(!ov)return;ov.innerHTML=html;ov.hidden=!html}

/* ---------- Spielablauf ---------- */
function begin(id,fromReplace){
  ctx.sess={id,seats:ctx.tour?ctx.tour.seats:seatsOf(),scores:[],turn:0};
  ctx.inGame=true;ctx.ov='';
  if(fromReplace)replace('game');else push('game');
  ctx.inGame=true;
  if(isNew(id)){startNew();return}
  nextTurn()}
function startNew(){const s=ctx.sess;ctx.ov='';setOv('');
  Sfx.music('game');
  AR.play(s.id,{seats:s.seats,difficulty:S.diff},r=>{Sfx.music('menu');finish({scores:r.scores,stats:r.stats,neu:true})},()=>{pause()})}
function nextTurn(){
  const s=ctx.sess,g=G[s.id],humans=s.seats.filter(x=>!x.cpu);
  if(g.versus){GA.skin=skinOf(s.seats[0].skin);
    const two=s.seats.length===2&&!s.seats[1].cpu;
    setOv(`<h2>${g.name}</h2><p>${two?esc(s.seats[0].name)+' spielt unten, '+esc(s.seats[1].name)+' oben.':esc(s.seats[0].name)+' spielt unten gegen die CPU ('+DN[S.diff].toLowerCase()+').'}</p><button class="btn" data-a="go">Los</button>`);
    ctx.run=()=>{setOv('');ctx.inGame=true;R.play(s.id,{skill:SK[S.diff],two},res=>finish({winner:res.winner}))};return}
  if(s.turn>=humans.length){
    s.seats.forEach((x,i)=>{if(x.cpu)s.scores[i]=g.cpuScore(SK[S.diff])});
    finish({scores:s.scores});return}
  const me=humans[s.turn];GA.skin=skinOf(me.skin);
  setOv(`${bimg(me.skin,70,true)}<p>${humans.length>1?'Handy an':''}</p><h2 style="color:${SEAT[me.card]}">${esc(me.name)}</h2><p>${g.help}</p><button class="btn" data-a="go">Los</button>`);
  ctx.run=()=>{setOv('');R.play(s.id,{skill:SK[S.diff]},res=>{s.scores[s.seats.indexOf(me)]=res.score;s.turn++;beep(520,.1);
    setOv(`<h2>${res.title}</h2><p>${esc(res.sub)}</p><button class="btn" data-a="cont">Weiter</button>`)})};
}
const TABLE={2:[3,0],3:[4,2,0],4:[5,3,1,0]};
function finish(o){
  const s=ctx.sess,g=G[s.id]||{best:'hoch'},n=s.seats.length;let order;
  if(o.neu){order=s.seats.map((_,i)=>i).sort((a,b)=>o.scores[b]-o.scores[a])}else if(o.winner!=null){order=[o.winner,1-o.winner];if(n<2)order=[0]}
  else{const hi=g.best==='hoch';order=s.seats.map((_,i)=>i).sort((a,b)=>hi?o.scores[b]-o.scores[a]:o.scores[a]-o.scores[b])}
  const pos=[];order.forEach((si,k)=>{const prev=k&&o.scores&&o.scores[si]===o.scores[order[k-1]]?pos[k-1]:k+1;pos.push(prev)});
  const scores=o.winner!=null?s.seats.map(()=>null):o.scores,pts=s.seats.map(()=>0),tb=TABLE[Math.min(Math.max(n,2),4)],fin=ctx.tour&&ctx.tour.round===ctx.tour.rounds-1;
  order.forEach((si,k)=>{const same=pos.filter(p=>p===pos[k]).length;let sum=0;for(let q=0;q<same;q++)sum+=tb[Math.min(pos[k]-1+q,tb.length-1)];pts[si]=Math.floor(sum/same)*(fin?2:1)});
  const tie=pos.length>1&&pos[0]===pos[1];let gain=0,rec=false,coins=0;const msgs=[];const winnerHuman=!s.seats[order[0]].cpu&&!tie;
  rollDaily();
  const hs=s.seats.map((st,i)=>i).filter(i=>!s.seats[i].cpu);
  S.played++;S.daily.games++;if(winnerHuman){S.wins++;S.daily.wins++}
  if(!S.kinds.includes(s.id))S.kinds.push(s.id);if(!S.daily.kinds.includes(s.id))S.daily.kinds.push(s.id);
  const best=scores&&scores[hs[0]]!=null?hs.map(i=>scores[i]):[];
  hs.forEach(i=>{if((o.neu||g.best)&&scores[i]!=null){const old=S.rec[s.id],hi=o.neu||g.best==='hoch';if(old==null||(hi?scores[i]>old:scores[i]<old)){if(!(hi&&scores[i]<=0)){S.rec[s.id]=scores[i];rec=old!=null}}}});
  const top=best.length?Math.max(...best.map(Math.abs)):0;
  if(o.neu&&o.stats){const st=o.stats;if(st.goals){S.goals+=st.goals;S.daily.goals+=st.goals}if(st.balls){S.balls+=st.balls;S.daily.balls+=st.balls}if(st.hits)S.hits+=st.hits;if(st.quiz){S.quiz+=st.quiz;S.daily.quiz+=st.quiz}if(st.reaction&&(!S.bestReact||st.reaction<S.bestReact))S.bestReact=st.reaction}
  if(!o.neu)['goals','balls','hits'].forEach(k=>{if(STAT[k].includes(s.id)&&top>0){const v=Math.min(Math.round(top),k==='goals'?8:20);S[k]+=v;if(k==='goals')S.daily.goals+=v;if(k==='balls')S.daily.balls+=v}});
  if(!o.neu&&s.id==='quiz'&&top>0){const v=Math.min(6,Math.max(1,Math.round(top/10)));S.quiz+=v;S.daily.quiz+=v}
  if(!o.neu&&(s.id==='reflex'||s.id==='reaction')&&best.length){const m=Math.min(...best);if(m>0&&m<900&&(!S.bestReact||m<S.bestReact))S.bestReact=m}
  coins=4+(winnerHuman?6:0);if(S.coinBoost>0){coins*=2;S.coinBoost--}addCoins(coins);
  gain=14+(winnerHuman?18:0)+(ctx.tour?6:0);if(S.xpBoost>0){gain*=2;S.xpBoost--}
  msgs.push(...addXP(gain),...checkAch(),...checkDaily());save();
  if(ctx.tour)ctx.tour.points=ctx.tour.points.map((p,i)=>p+pts[i]);
  ctx.res={seats:s.seats,order,pos,scores,pts,gain,coins,rec,winnerHuman,tie,msgs};beep(winnerHuman?660:330,.25);buzz(30);if(winnerHuman)setTimeout(confetti,300);
  ctx.inGame=false;replace('result');
}
function pause(){if(!ctx.inGame)return;if(isNew(ctx.sess.id)){AR.pause();ctx.prevOv='';setOv(`<h2>Pause</h2><p>${esc(RULES[ctx.sess.id]||'')}</p><button class="btn" data-a="resume">▶ Weiter</button><button class="btn alt" data-a="restart">Neu starten</button><button class="btn red" data-a="quit">${ctx.tour?'Turnier abbrechen':'Zur Spielwahl'}</button>`);return}R.pause();ctx.prevOv=ctx.ov;setOv('<h2>Pause</h2><button class="btn" data-a="resume">Weiterspielen</button><button class="btn alt" data-a="quit">Spiel beenden</button>')}

/* ---------- Eingaben ---------- */
$app.addEventListener('click',e=>{
  const t=e.target.closest('button,a');if(!t||t.tagName==='A')return;
  const d=t.dataset;ac();if(S.music&&!mus)music();beep(520,.05,'square',.04);buzz(8);
  if(d.f){ctx.filter=d.f;render('picker');return}
  if(d.d){S.diff=+d.d;save();render('setup');return}
  if(d.r){ctx.rounds=+d.r;render('tsetup');return}
  if(d.slot){const[c,m]=d.slot.split(':');const old=S.slots[+c];S.slots[+c]=m;if(S.slots.filter(x=>x!=='off').length<2){S.slots[+c]=old;toast('Es braucht mindestens 2 Spieler.')}if(!S.slots.includes('human')){S.slots[+c]=old;toast('Mindestens ein Mensch muss mitspielen.')}save();render('setup');return}
  if(d.skin!=null){const i=+d.skin,own=S.unlocked,k=own.indexOf(S.skinIds[i]);S.skinIds[i]=own[(k+1)%own.length];save();render('setup');return}
  if(d.tab){ctx.tab=d.tab;render('shop');return}
  if(d.tg){S[d.tg]=!S[d.tg];save();if(d.tg==='music')music();render('settings');return}
  if(d.buy){const k=skinOf(d.buy);if(S.coins>=k.price&&!S.unlocked.includes(k.id)){S.coins-=k.price;S.unlocked.push(k.id);const m=checkAch();save();toast(m[0]||k.name+' gekauft')}render('shop');return}
  if(d.eq){const[k,c]=d.eq.split(':');S.skinIds[+c]=k;save();render('shop');return}
  if(d.buyi){const it=M.TITLES.find(x=>x.id===d.buyi),price=it?it.price:+d.price;if(S.coins>=price&&!S.items.includes(d.buyi)){S.coins-=price;S.items.push(d.buyi);if(it)S.titleId=it.id;else S.cheerId=d.buyi.slice(2);save();toast('Gekauft')}render('shop');return}
  if(d.eqt){S.titleId=d.eqt;save();render('shop');return}
  if(d.eqc){S.cheerId=d.eqc;save();render('shop');return}
  if(d.boost){const b=M.BOOSTS.find(x=>x.id===d.boost);if(S.coins>=b.price){S.coins-=b.price;if(b.id==='coin2')S.coinBoost+=10;else S.xpBoost+=10;save();toast('Booster aktiv')}render('shop');return}
  if(d.g){if(d.ok!=='1'){toast(G[d.g]?'Duell-Spiele gehen nur zu zweit.':'Dieses Spiel gibt es in der App.');return}
    ctx.tour=null;ctx.sess={id:d.g,seats:seatsOf()};push('intro');return}
  switch(d.a){
   case'back':history.back();break;
   case'setup':push('setup');break;
   case'tour':ctx.mode='tour';ctx.tour=null;if(location.hash==='#podium')replace('tsetup');else push('tsetup');break;
   case'picker':ctx.tour=null;push('picker');break;
   case'picker2':ctx.tour=null;replace('picker');break;
   case'stats':push('stats');break;
   case'shop':push('shop');break;
   case'ach':push('ach');break;
   case'wheel':ctx.spin=false;push('wheel');break;
   case'settings':ctx.confirmReset=false;push('settings');break;
   case'random':{const p=gamesFor(nSeats());ctx.tour=null;ctx.sess={id:p[Math.floor(Math.random()*p.length)],seats:seatsOf()};push('intro');break}
   case'spin':{if(!canWheel()||ctx.spin)break;ctx.spin=true;let r=Math.random()*M.WHEEL.reduce((a,p)=>a+p.weight,0),k=0;for(;k<M.WHEEL.length;k++){if(r<M.WHEEL[k].weight)break;r-=M.WHEEL[k].weight}k=Math.min(k,M.WHEEL.length-1);
     const pz=M.WHEEL[k],bonus=Math.min(Math.max(S.streak,1),7)*5;S.lastWheel=M.key();
     if(pz.kind==='coins')addCoins(pz.amount);else if(pz.kind==='xp')addXP(pz.amount);else S.coinBoost+=pz.amount;addCoins(bonus);const m=checkAch();save();
     const seg=360/M.WHEEL.length,wh=document.getElementById('wh');wh.style.transform='rotate('+(360*7-(k*seg+seg/2))+'deg)';
     document.querySelector('[data-a=spin]').disabled=true;beep(440,.1);{let d=45,el=0;const tick=()=>{if(el>4700)return;beep(1500,.015);d*=1.075;el+=d;setTimeout(tick,d)};tick()}
     setTimeout(()=>{const e=document.getElementById('wres');if(e)e.textContent=(pz.kind==='boost'?'Booster x2 (5 Spiele)':pz.label+' '+pz.sub)+' + '+bonus+' Münzen';beep(880,.3);confetti();if(m.length)toast(m[0]);ctx.spin=false},matchMedia('(prefers-reduced-motion:reduce)').matches?100:5100);break}
   case'start':begin(ctx.sess.id);break;
   case'go':ctx.run&&ctx.run();break;
   case'cont':nextTurn();break;
   case'again':begin(ctx.sess.id,true);break;
   case'share':shareRes();break;
   case'home':ctx.tour=null;replace('hub');break;
   case'pause':pause();break;
   case'resume':setOv(ctx.prevOv||'');if(isNew(ctx.sess.id))AR.resume();else R.resume();break;
   case'restart':begin(ctx.sess.id,true);break;
   case'quit':ctx.inGame=false;R.stop();AR.stop();ctx.ov='';ctx.tour=null;history.back();break;
   case'tourgo':{const seats=seatsOf();ctx.tour={round:0,rounds:ctx.rounds,seats,points:seats.map(()=>0),last:null,next:null};pickRound();push('tour');break}
   case'tourplay':ctx.sess={id:ctx.tour.next,seats:ctx.tour.seats};begin(ctx.tour.next);break;
   case'next':{const tr=ctx.tour;tr.round++;if(tr.round>=tr.rounds){S.tPlayed++;const ord=tr.seats.map((_,i)=>i).sort((a,b)=>tr.points[b]-tr.points[a]);if(!tr.seats[ord[0]].cpu&&(ord.length<2||tr.points[ord[0]]>tr.points[ord[1]])){S.tWon++;confetti()}const m=checkAch();save();if(m.length)toast(m[0]);replace('podium')}else{pickRound();replace('tour')}break}
   case'reset':if(ctx.confirmReset){S=defS();rollDaily();ctx.confirmReset=false;save();toast('Fortschritt gelöscht')}else ctx.confirmReset=true;render('settings');break;
  }});
$app.addEventListener('input',e=>{const i=e.target.dataset.name;if(i!=null){S.names[+i]=e.target.value;save()}});
function pickRound(){const t=ctx.tour,pool=gamesFor(t.seats.length).filter(id=>id!==t.last);t.next=pool[Math.floor(Math.random()*pool.length)];t.last=t.next}
window.__app={ctx,S:()=>S,render};
render('hub');
})();
