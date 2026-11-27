(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label,Rand}=SK;
const rr=(a,b)=>a+Math.random()*(b-a);
let MAXT=5;
class BowlingGame extends MiniScene{
 static get layout(){return 'turns'}
 setupGame(){MAXT=this.seats.length>=3?3:4;this.turnWait=0;this.lanes=[];this.finishing=false;for(const s of this.seats){const l={seat:s,pins:[],ball:null,ballSpin:null,bpos:{x:0,y:0},bvel:{x:0,y:0},spinAcc:0,gutter:false,ballDone:false,mode:'ready',throwsDone:0,timer:0,rollT:0,laneW:200,gutW:14,pr:10,br:14,y0:0,backY:0,headY:0,sx:28,counter:null,hint:null,bear:null,touch:null,touchStart:{x:0,y:0},samples:[],idle:0,cpuWait:1,lastHit:-1,trailT:0};this.lanes.push(l);this.buildL(l);this.newBall(l)}this.setActiveSeat(0)}
 buildL(l){const s=l.seat,w=s.w,h=s.h,narrow=w<250;l.laneW=narrow?w*.82:250;l.gutW=Math.max(8,Math.min(16,(w-l.laneW)/2-1));l.pr=narrow?8.5:10.5;l.br=l.pr*1.45;l.sx=l.pr*2.7;const dy=l.sx*.87;l.backY=h/2-46;l.headY=l.backY-3*dy;l.y0=-h/2+l.br+36;
  const homes=[];for(let row=0;row<4;row++){const cnt=row+1,y=l.headY+row*dy;for(let k=0;k<cnt;k++)homes.push({x:(k-(cnt-1)/2)*l.sx,y})}
  const tw=w-6,th=h-6,lane=new Sprite(this.laneTex(tw,th,l.laneW,l.gutW,homes,l.pr,s.index,s.color),tw,th);lane.z=-30;s.field.add(lane);
  for(const hp of homes){const sh=new Sprite(Gfx.shadow(),l.pr*3.2,l.pr*1.3);sh.x=1.5;sh.y=-2;sh.z=-1;const pin={node:new Node(),visual:new Node(),shadow:sh,pos:{x:hp.x,y:hp.y},vel:{x:0,y:0},home:hp,fallen:false,get moving(){return this.vel.x!==0||this.vel.y!==0}};
   pin.node.x=hp.x;pin.node.y=hp.y;pin.node.z=20-hp.y*.01;pin.node.add(sh);const sp=new Sprite(this.pinTex(l.pr),l.pr*1.9,l.pr*4.6);sp.ay=.1;pin.visual.add(sp);pin.node.add(pin.visual);s.field.add(pin.node);l.pins.push(pin)}
  const pw=narrow?76:92,pill=new Sprite(Gfx.pill(pw,18,white(0,.6),s.color.replace(/[\d.]+\)$/,'.6)'),9,false),pw,18);pill.x=-w/2+12+pw/2;pill.y=h/2-36;pill.z=399;s.node.add(pill);
  const c=label('WURF 1/'+MAXT,narrow?11:13,'#fff');c.x=pill.x;c.y=pill.y;c.z=400;s.node.add(c);l.counter=c;
  const hl=label('NACH OBEN WISCHEN',narrow?11:14,'#fff');hl.y=l.y0+62;hl.z=60;const hw=narrow?142:176,hbg=new Sprite(Gfx.pill(hw,22,white(0,.55),null,11,false),hw,22);hbg.z=-1;hl.add(hbg);s.field.add(hl);
  hl.run(A.forever(A.sequence([A.fadeTo(.45,.5),A.fadeTo(1,.5)])));hl.run(A.sequence([A.wait(6),A.fadeOut(.3),A.remove()]),'hintOut');l.hint=hl;
  const bear=this.makeBear(s,narrow?38:50,true);bear.x=-w/2+(narrow?20:34);bear.y=-h/2+8;bear.z=30;s.field.add(bear);bear.startBob(2,.5);l.bear=bear}
 laneTex(w,h,laneW,gut,homes,pr,idx,color){w=Math.floor(w);h=Math.floor(h);return Gfx.texture('bowl_lane_'+w+'_'+h+'_'+idx,w,h,1.5,c=>{
  c.save();c.beginPath();SK.rr(c,0,0,w,h,15);c.clip();c.fillStyle=rgba(.05,.04,.1);c.fillRect(0,0,w,h);const lx=(w-laneW)/2;
  c.save();c.beginPath();c.rect(lx,0,laneW,h);c.clip();Gfx.gradientColors(c,rgba(.5,.3,.14),rgba(.8,.55,.3),w,h);const rnd=new Rand(31),boards=11;
  for(let b=0;b<=boards;b++){const x=lx+laneW*b/boards;c.strokeStyle='rgba(0,0,0,.18)';c.lineWidth=.8;c.beginPath();c.moveTo(x,0);c.lineTo(x,h);c.stroke();if(b<boards){c.fillStyle=(rnd.double()>.5?'rgba(255,255,255,':'rgba(0,0,0,')+rnd.range(.02,.07)+')';c.fillRect(x,0,laneW/boards,h)}}
  const deckBottom=h/2-Math.min(...homes.map(p=>p.y))+pr*3;c.fillStyle='rgba(255,255,255,.06)';c.fillRect(lx,0,laneW,deckBottom);
  c.fillStyle='rgba(38,38,38,.35)';const ay=h*.62;for(let k=-2;k<=2;k++){const ax=w/2+k*laneW*.16,off=Math.abs(k)*9;c.beginPath();c.moveTo(ax,ay-12+off);c.lineTo(ax-5,ay+6+off);c.lineTo(ax+5,ay+6+off);c.closePath();c.fill()}
  c.fillStyle='rgba(255,255,255,.3)';for(const hp of homes){const r=pr*.45;c.beginPath();c.ellipse(w/2+hp.x,h/2-hp.y,r,r*.6,0,0,7);c.fill()}
  c.fillStyle='rgba(255,77,77,.7)';c.fillRect(lx,h-26,laneW,2);c.restore();
  for(const gx of [lx-gut,lx+laneW]){c.fillStyle=rgba(.04,.04,.04);c.fillRect(gx,0,gut,h);c.fillStyle=rgba(.16,.16,.16);c.fillRect(gx+gut*.35,0,gut*.3,h)}
  c.strokeStyle=color.replace(/[\d.]+\)$/,'.9)');c.lineWidth=2;for(const ex of [lx,lx+laneW]){c.beginPath();c.moveTo(ex,0);c.lineTo(ex,h);c.stroke()}c.restore()})}
 pinTex(pr){const W=pr*1.9,H=pr*4.6;return Gfx.texture('bowl_pin_'+Math.floor(pr*10),W,H,3,c=>{const cx=W/2,baseY=H*.9,bodyR=W*.46,neckW=W*.34,headR=W*.27;
  const belly=[cx,baseY-bodyR*1.3,bodyR,bodyR*1.3],neck=[cx-neckW/2,H*.18,neckW,baseY-bodyR*1.4-H*.18],head=[cx,H*.03+headR,headR,headR];
  const el=a=>{c.beginPath();c.ellipse(a[0],a[1],a[2],a[3],0,0,7)};c.fillStyle=white(.97);el(belly);c.fill();c.fillRect(...neck);el(head);c.fill();
  c.save();c.beginPath();c.ellipse(...belly,0,0,7);c.rect(...neck);c.moveTo(head[0]+head[2],head[1]);c.ellipse(...head,0,0,7);c.clip();
  c.fillStyle='rgba(140,140,140,.45)';c.fillRect(cx+bodyR*.25,0,W,H);c.fillStyle='rgba(255,255,255,.5)';c.fillRect(cx-bodyR*.65,0,bodyR*.2,H);c.fillStyle=rgba(.9,.1,.15);c.fillRect(0,H*.34,W,H*.045);c.fillRect(0,H*.41,W,H*.03);c.restore();
  c.strokeStyle='rgba(64,64,64,.6)';c.lineWidth=.6;el(belly);c.stroke();el(head);c.stroke()})}
 ballTex(br,idx,color){const d=br*2;return Gfx.texture('bowl_ball_'+Math.floor(br)+'_'+idx+'_'+color,d,d,3,c=>{c.save();c.beginPath();c.arc(br,br,br-.5,0,7);c.clip();
  const m=color.match(/[\d.]+/g).map(Number),mx=(v)=>Math.min(255,v+90),g=c.createRadialGradient(br*.7,br*.7,0,br,br,br*1.15);g.addColorStop(0,'rgb('+mx(m[0])+','+mx(m[1])+','+mx(m[2])+')');g.addColorStop(.45,color);g.addColorStop(1,'rgb('+Math.floor(m[0]*.25)+','+Math.floor(m[1]*.25)+','+Math.floor(m[2]*.25)+')');c.fillStyle=g;c.fillRect(0,0,d,d);c.restore();c.strokeStyle='rgba(0,0,0,.6)';c.lineWidth=1;c.beginPath();c.arc(br,br,br-.5,0,7);c.stroke()})}
 newBall(l){const s=l.seat;l.ball=new Node();l.ballSpin=new Node();l.bpos={x:0,y:l.y0};l.bvel={x:0,y:0};l.spinAcc=0;l.gutter=false;l.ballDone=false;l.mode='ready';l.idle=0;l.cpuWait=.8+Math.random()*.5;l.touch=null;l.samples=[];const b=l.ball;b.x=l.bpos.x;b.y=l.bpos.y;b.z=40;
  const sh=new Sprite(Gfx.shadow(),l.br*3,l.br*1.2);sh.x=2;sh.y=-l.br*.8;sh.z=-2;b.add(sh);const gl=new Sprite(Gfx.glow(),l.br*3.6,l.br*3.6);gl.color=s.color;gl.cbf=1;gl.blend='add';gl.alpha=.45;gl.z=-1;b.add(gl);
  b.add(new Sprite(this.ballTex(l.br,s.index,s.color),l.br*2,l.br*2));for(const [dx,dy] of [[-.25,.3],[.12,.38],[-.02,.1]]){const ho=new Sprite(Gfx.dot(),l.br*.28,l.br*.28);ho.color=white(.05);ho.cbf=1;ho.alpha=.85;ho.x=dx*l.br;ho.y=dy*l.br;l.ballSpin.add(ho)}
  l.ballSpin.z=1;b.add(l.ballSpin);const hi=new Sprite(Gfx.dot(),l.br*.5,l.br*.5);hi.alpha=.55;hi.x=-l.br*.35;hi.y=l.br*.4;hi.z=2;b.add(hi);b.setScale(.2);b.run(A.scaleTo(1,.2));s.field.add(b);this.updCounter(l)}
 updCounter(l){if(l.mode==='done')l.counter.text='FERTIG';else{const n=l.mode==='ready'?l.throwsDone+1:l.throwsDone;l.counter.text='WURF '+Math.min(MAXT,Math.max(1,n))+'/'+MAXT}}
 resetPins(l){l.pins.forEach((p,i)=>{p.pos={x:p.home.x,y:p.home.y};p.vel={x:0,y:0};p.fallen=false;p.node.x=p.home.x;p.node.y=p.home.y;p.node.z=20-p.home.y*.01;p.visual.removeAction('top');p.visual.rot=0;p.visual.alpha=1;p.shadow.alpha=1;p.node.setScale(.1);p.node.run(A.sequence([A.wait(i*.025),A.scaleTo(1.15,.12),A.scaleTo(1,.08)]))})}
 pinsDown(l){return l.pins.filter(p=>p.fallen).length}
 launch(l,dir,speed,spin){if(l.mode!=='ready')return;l.bvel={x:dir.x*speed,y:dir.y*speed};l.spinAcc=spin;l.mode='rolling';l.rollT=0;l.throwsDone++;if(l.hint){l.hint.removeAction('hintOut');l.hint.run(A.sequence([A.fadeOut(.2),A.remove()]));l.hint=null}l.bear.squash();Sfx.play('kick');if(!l.seat.isCPU)Haptic.tap('medium');this.updCounter(l)}
 cpuThrow(l){const sk=l.seat.skill,sx0=rr(-1,1)*l.laneW*.18;l.bpos.x=sx0;l.ball.x=sx0;const side=Math.random()<.5?1:-1,tx=side*l.sx*.28;let ang=Math.atan2(tx-sx0,l.headY-l.bpos.y);ang+=rr(-1,1)*(1-sk)*.17;this.launch(l,{x:Math.sin(ang),y:Math.cos(ang)},rr(360,470),0)}
 began(seat,at,id){const l=this.lanes[seat.index];if(l.mode!=='ready'||l.touch!==null)return;l.touch=id;l.touchStart={x:at.x,y:at.y};l.samples=[{p:{x:at.x,y:at.y},t:this.elapsed}];l.idle=0;Haptic.tap('light')}
 moved(seat,at,id){const l=this.lanes[seat.index];if(l.mode!=='ready'||l.touch!==id)return;l.samples.push({p:{x:at.x,y:at.y},t:this.elapsed});if(l.samples.length>40)l.samples.shift();const lim=l.laneW/2-l.br;
  l.bpos={x:Math.max(-lim,Math.min(lim,(at.x-l.touchStart.x)*.9)),y:l.y0+Math.max(0,Math.min(70,at.y-l.touchStart.y))};l.ball.x=l.bpos.x;l.ball.y=l.bpos.y;l.ballSpin.rot=(at.y-l.touchStart.y)*.03}
 ended(seat,at,id){const l=this.lanes[seat.index];if(l.mode!=='ready'||l.touch!==id)return;l.touch=null;l.samples.push({p:{x:at.x,y:at.y},t:this.elapsed});const now=this.elapsed,recent=l.samples.filter(o=>now-o.t<.14);
  const reject=()=>{l.bpos={x:0,y:l.y0};l.ball.run(A.moveTo(0,l.y0,.15));seat.floatText('SCHWUNG!',{x:0,y:l.y0+40},'#fff',14)};
  if(recent.length<2){reject();return}const f=recent[0],e=recent[recent.length-1],dt=Math.max(.02,e.t-f.t),vx=(e.p.x-f.p.x)/dt,vy=(e.p.y-f.p.y)/dt,sp=Math.hypot(vx,vy);if(sp<250||vy<120){reject();return}
  let ang=Math.max(-.5,Math.min(.5,Math.atan2(vx,vy)));const speed=Math.max(300,Math.min(540,sp*.4));let spin=0;const pts=l.samples.filter(o=>now-o.t<.3);
  if(pts.length>=5){const mid=pts[Math.floor(pts.length/2)],a1=Math.atan2(mid.p.x-pts[0].p.x,Math.max(1,mid.p.y-pts[0].p.y)),a2=Math.atan2(e.p.x-mid.p.x,Math.max(1,e.p.y-mid.p.y)),diff=a2-a1;if(Math.abs(diff)>.1)spin=Math.max(-120,Math.min(120,diff*240))}
  this.launch(l,{x:Math.sin(ang),y:Math.cos(ang)},speed,spin)}
 advanceTurn(){const n=this.seats.length;for(let k=1;k<=Math.max(1,n);k++){const j=(this.activeSeatIndex+k)%n;if(this.lanes[j].mode!=='done'){this.lanes[j].idle=0;this.lanes[j].cpuWait=.8+Math.random()*.5;this.setActiveSeat(j);return}}}
 gameUpdate(dt){const l=this.lanes[this.activeSeatIndex];/* Schuss für Schuss abwechseln */{const a=this.activeSeatIndex,q=this.lanes[a];if(q&&this.seats.length>1){if(this._ta!==a){this._ta=a;this._ts=q.throwsDone;this._tw=0}else if(q.throwsDone>this._ts&&q.mode==='ready'){this._tw+=dt;if(this._tw>.8){this._ta=-1;this.advanceTurn();if(this.activeSeatIndex!==a)return}}}}
  if(l.mode==='ready'){l.idle+=dt;if(l.seat.isCPU){l.cpuWait-=dt;if(l.cpuWait<=0)this.cpuThrow(l)}else if(l.idle>14&&l.touch===null){const a=rr(-.12,.12);this.launch(l,{x:Math.sin(a),y:Math.cos(a)},400,0)}}
  else if(l.mode==='rolling'){l.rollT+=dt;this.stp(l,dt);if((l.ballDone&&!l.pins.some(p=>p.moving))||l.rollT>6){for(const p of l.pins)p.vel={x:0,y:0};if(!l.ballDone)this.removeBall(l);l.mode='settling';l.timer=.9;this.evaluate(l)}}
  else if(l.mode==='settling'){l.timer-=dt;if(l.timer<=0)this.nextL(l)}
  if(!this.finishing&&this.lanes[this.activeSeatIndex].mode==='done'){this.turnWait+=dt;if(this.turnWait>1.1){this.turnWait=0;this.advanceTurn()}}
  if(!this.finishing&&this.elapsed>70*Math.max(1,this.seats.length))this.finishAll()}
 stp(l,dt){const sub=3,h=dt/sub,pr=l.pr,br=l.br,half=l.laneW/2;
  for(let k=0;k<sub;k++){
   if(!l.ballDone){if(!l.gutter)l.bvel.x+=l.spinAcc*h;l.bpos.x+=l.bvel.x*h;l.bpos.y+=l.bvel.y*h;
    if(l.gutter){const tg=(l.bpos.x<0?-1:1)*(half+l.gutW/2);l.bpos.x+=(tg-l.bpos.x)*Math.min(1,12*h)}
    else if(Math.abs(l.bpos.x)>half-br*.35&&l.bpos.y<l.headY-25){l.gutter=true;l.bvel.x=0;l.spinAcc=0;l.seat.floatText('RINNE!',{x:l.bpos.x*.5,y:l.bpos.y+40},white(.85),16);Sfx.play('miss');l.ball.run(A.scaleTo(.85,.2))}
    if(!l.gutter){const lim=half-br*.5;if(l.bpos.x>lim){l.bpos.x=lim;l.bvel.x=-Math.abs(l.bvel.x)*.5}if(l.bpos.x<-lim){l.bpos.x=-lim;l.bvel.x=Math.abs(l.bvel.x)*.5}
     for(const p of l.pins){const dx=p.pos.x-l.bpos.x,dy=p.pos.y-l.bpos.y;let d=Math.hypot(dx,dy);const minD=pr+br*.9;if(d>=minD)continue;let nx=dx/Math.max(d,.001),ny=dy/Math.max(d,.001);if(d<.001){nx=0;ny=1;d=.001}
      const ov=minD-d;p.pos.x+=nx*ov*.8;p.pos.y+=ny*ov*.8;l.bpos.x-=nx*ov*.2;l.bpos.y-=ny*ov*.2;const vr=(l.bvel.x-p.vel.x)*nx+(l.bvel.y-p.vel.y)*ny;
      if(vr>0){const mb=6,mp=1,j=1.7*vr/(1/mb+1/mp);l.bvel.x-=j/mb*nx;l.bvel.y-=j/mb*ny;p.vel.x+=j/mp*nx;p.vel.y+=j/mp*ny;this.topple(l,p,vr)}}}
    const sp=Math.hypot(l.bvel.x,l.bvel.y);l.ballSpin.rot+=h*sp*.05;if(l.bpos.y>l.backY+pr*2+6||(sp<25&&l.bpos.y>l.headY-10)||l.bpos.y<-l.seat.h/2)this.removeBall(l)}
   const lim=half-pr;
   for(const p of l.pins){if(!p.moving)continue;const sp=Math.hypot(p.vel.x,p.vel.y),nsp=sp*Math.exp(-3.6*h);if(nsp<9){p.vel={x:0,y:0};continue}const kk=nsp/sp;p.vel.x*=kk;p.vel.y*=kk;p.pos.x+=p.vel.x*h;p.pos.y+=p.vel.y*h;
    if(p.pos.x>lim){p.pos.x=lim;p.vel.x=-Math.abs(p.vel.x)*.5}if(p.pos.x<-lim){p.pos.x=-lim;p.vel.x=Math.abs(p.vel.x)*.5}if(p.pos.y>l.backY+pr+12){p.pos.y=l.backY+pr+12;p.vel.y=-Math.abs(p.vel.y)*.5}if(p.pos.y<-l.seat.h/2+pr){p.pos.y=-l.seat.h/2+pr;p.vel.y=Math.abs(p.vel.y)*.5}}
   for(let i=0;i<l.pins.length;i++)for(let j=i+1;j<l.pins.length;j++){const a=l.pins[i],b=l.pins[j];if(!a.moving&&!b.moving)continue;let dx=b.pos.x-a.pos.x,dy=b.pos.y-a.pos.y,d=Math.hypot(dx,dy);if(d>=2*pr)continue;if(d<.001){dx=0;dy=1;d=1}const nx=dx/d,ny=dy/d,ov=(2*pr-d)/2;a.pos.x-=nx*ov;a.pos.y-=ny*ov;b.pos.x+=nx*ov;b.pos.y+=ny*ov;
    const vr=(a.vel.x-b.vel.x)*nx+(a.vel.y-b.vel.y)*ny;if(vr>0){const j2=vr*1.7/2;a.vel.x-=j2*nx;a.vel.y-=j2*ny;b.vel.x+=j2*nx;b.vel.y+=j2*ny;if(vr>8){this.topple(l,a,vr);this.topple(l,b,vr)}}}}
  l.ball.x=l.bpos.x;l.ball.y=l.bpos.y;for(const p of l.pins){p.node.x=p.pos.x;p.node.y=p.pos.y;p.node.z=p.fallen?15:20-p.pos.y*.01}
  if(!l.ballDone){l.trailT-=dt;if(l.trailT<=0){l.trailT=.03;const t=new Sprite(Gfx.dot(),br*1.1,br*1.1);t.color=l.seat.color;t.cbf=1;t.blend='add';t.alpha=.5;t.x=l.bpos.x;t.y=l.bpos.y;t.z=5;l.seat.field.add(t);t.run(A.sequence([A.group([A.fadeOut(.35),A.scaleTo(.3,.35)]),A.remove()]))}}}
 topple(l,p,strength){if(p.fallen)return;p.fallen=true;const dx=p.vel.x,dy=p.vel.y;let ang=Math.atan2(-dx,dy);if(Math.hypot(dx,dy)<1)ang=1.4;p.visual.run(A.sequence([A.rotateTo(ang,.22),A.fadeTo(.6,.5)]),'top');p.shadow.run(A.fadeTo(.3,.3));
  if(this.elapsed-l.lastHit>.045){l.lastHit=this.elapsed;Sfx.play('hit')}l.seat.burst(p.pos,'#fff',strength>250?7:4,strength>250?90:60);if(strength>150&&!l.seat.isCPU)Haptic.tap('light');if(strength>250)l.seat.shake(2.5)}
 removeBall(l){if(l.ballDone)return;l.ballDone=true;l.ball.run(A.sequence([A.group([A.fadeOut(.25),A.scaleTo(.6,.25)]),A.remove()]))}
 evaluate(l){const s=l.seat,n=this.pinsDown(l);let gain=n;const strike=n===l.pins.length;if(strike)gain+=5;if(gain>0)this.addScore(s,gain);this.addStat('hits',n,s);const cx=0,cy=l.headY+30;
  if(strike){s.banner('STRIKE!','#ff0',42,.7);s.flash('#ff0',.3);s.burst({x:cx,y:cy},'#ff0',30,180);s.burst({x:cx,y:cy},s.color,20,130);s.floatText('+'+gain,{x:cx,y:cy-30},'#ff0',30);Sfx.play('fanfare');Haptic.good();l.bear.celebrate();this.addStat('goals',1,s);s.shake(6);
   const ring=new Sprite(Gfx.circle(40,'rgba(0,0,0,0)','#ff0'),80,80);ring.blend='add';ring.x=cx;ring.y=cy;ring.z=60;s.field.add(ring);ring.run(A.sequence([A.group([A.scaleTo(5,.5),A.fadeOut(.5)]),A.remove()]))}
  else if(n>0){s.floatText('+'+n,{x:cx,y:cy-20},s.color,26);Sfx.play(n>=7?'right':'pop');if(n>=7)s.burst({x:cx,y:cy},s.color,14,110)}
  else{s.floatText(l.gutter?'RINNE':'DANEBEN',{x:cx,y:cy-20},white(.85),16);Sfx.play('wrong')}}
 nextL(l){if(l.throwsDone>=MAXT){l.mode='done';this.updCounter(l);l.bear.stopBob();if(this.lanes.every(o=>o.mode==='done'))this.finishAll()}else{this.resetPins(l);this.newBall(l)}}
 finishAll(){if(this.finishing)return;this.finishing=true;this.run(A.sequence([A.wait(.4),A.run(()=>this.finishGame())]))}
}
Arcade.register('bowling',BowlingGame);
})();
