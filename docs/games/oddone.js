(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label,rr,Rand}=SK;
const COLORS=[[.2,.95,1],[1,.3,.75],[.6,1,.25],[1,.7,.1],[.7,.5,1]];
const ROUNDS=10;
const rgb2hsv=([r,g,b])=>{const mx=Math.max(r,g,b),mn=Math.min(r,g,b),d=mx-mn;let h=0;if(d){if(mx===r)h=((g-b)/d)%6;else if(mx===g)h=(b-r)/d+2;else h=(r-g)/d+4;h/=6;if(h<0)h+=1}return[h,mx?d/mx:0,mx]};
const hsv2rgb=(h,s,v)=>{const i=Math.floor(h*6),f=h*6-i,p=v*(1-s),q=v*(1-f*s),t=v*(1-(1-f)*s);return[[v,t,p],[q,v,p],[p,v,t],[p,q,v],[t,p,v],[v,p,q]][i%6]};
class OddOneGame extends MiniScene{
 static shapeTexture(kind,size){return Gfx.texture('oddone_shape_'+kind+'_'+Math.floor(size),size,size,2,c=>{const s=size,m=s*.08;c.fillStyle='#fff';c.beginPath();
  if(kind===0)c.ellipse(s/2,s/2,s/2-m,s/2-m,0,0,Math.PI*2);else if(kind===1)rr(c,m,m,s-2*m,s-2*m,s*.16);
  else if(kind===2){c.moveTo(s/2,m);c.lineTo(s-m,s/2);c.lineTo(s/2,s-m);c.lineTo(m,s/2)}else{c.moveTo(s/2,m);c.lineTo(s-m,s-m);c.lineTo(m,s-m)}c.closePath();c.fill()})}
 setupGame(){this.states=[];this.round=0;this.roundTime=0;this.waiting=false;this.timeoutArmed=false;
  for(const s of this.seats){const st={rand:this.newRand(),cells:[],odd:0,lock:0,done:false,cpuTimer:0};st.cols=s.w>300?4:3;const avail=Math.min(s.w-24,s.h-100);st.cell=Math.floor(avail/st.cols);
   st.cy=(s.h/2-36+(-s.h/2+8))/2-4;const n=st.cols*st.cols,gw=st.cell*st.cols;
   const panel=new Sprite(Gfx.pill(gw+12,gw+12,white(.05,.7),white(1,.2),18),gw+12,gw+12);panel.y=st.cy;panel.z=1;s.field.add(panel);
   for(let i=0;i<n;i++){const c=new Sprite(OddOneGame.shapeTexture(0,64),st.cell*.78,st.cell*.78),col=i%st.cols,row=Math.floor(i/st.cols);c.x=(col-(st.cols-1)/2)*st.cell;c.y=st.cy+(row-(st.cols-1)/2)*st.cell;c.z=3;c.cbf=1;c.alpha=.25;s.field.add(c);st.cells.push(c)}
   st.roundLabel=label('Runde 1/'+ROUNDS,13,white(1,.7));st.roundLabel.ha='left';st.roundLabel.x=-s.w/2+14;st.roundLabel.y=s.h/2-22;st.roundLabel.z=6;s.field.add(st.roundLabel);
   const hint=label('TIPPE DEN AUSREISSER',Math.min(15,s.w*.07),'#fff');hint.y=st.cy+gw/2+22;hint.z=7;s.field.add(hint);hint.run(A.sequence([A.wait(3.5),A.fadeOut(.5)]));this.states.push(st)}}
 gameStarted(){this.newRound()}
 newRound(){this.round++;this.waiting=false;this.roundTime=0;this.timeoutArmed=false;this.scheduleTimeout(7.5);
  const seed=new Rand(this.sharedSeed+this.round*7919),kind=seed.int(0,3),colIdx=seed.int(0,COLORS.length-1),diff=Math.max(.18,.55-this.round*.04),sameShapeDiff=seed.chance(.5);
  for(const s of this.seats){const st=this.states[s.index];st.done=false;st.lock=0;st.odd=new Rand(this.sharedSeed+this.round*104729).int(0,st.cells.length-1);st.roundLabel.text='Runde '+this.round+'/'+ROUNDS;
   const base=COLORS[colIdx],[h,sa,b]=rgb2hsv(base),oddCol=rgba(...hsv2rgb((h+diff*.22+1)%1,sa,b)),baseCol=rgba(...base);
   st.cells.forEach((c,i)=>{const isOdd=i===st.odd;c.removeAllActions();const alt=isOdd&&sameShapeDiff&&this.round>3,k=alt?(kind+1)%4:kind;c.texture=OddOneGame.shapeTexture(k,64);
    c.color=(isOdd&&!alt)?oddCol:baseCol;c.alpha=1;c.setScale(.1);c.run(A.sequence([A.wait(i*.012),A.scaleTo(1,.14)]))});
   if(s.isCPU)st.cpuTimer=.9+(1-s.skill)*3.2+Math.random()*.8+this.round*.12}}
 gameUpdate(dt){if(this.waiting)return;this.roundTime+=dt;
  for(const s of this.seats){const st=this.states[s.index];if(st.lock>0)st.lock-=dt;
   if(s.isCPU&&!st.done&&st.lock<=0){st.cpuTimer-=dt;if(st.cpuTimer<=0){if(Math.random()<.55+s.skill*.4)this.tap(s,st.odd);else{let w=Math.floor(Math.random()*st.cells.length);if(w===st.odd)w=(w+1)%st.cells.length;this.tap(s,w);st.cpuTimer=.8+(1-s.skill)}}}}}
 tap(s,idx){const st=this.states[s.index];if(st.done||st.lock>0||this.waiting)return;const c=st.cells[idx];
  if(idx===st.odd){const pts=this.roundTime<2.5?3:(this.roundTime<5?2:1);this.addScore(s,pts);this.addStat('hits',1,s);st.done=true;s.burst({x:c.x,y:c.y},c.color,12,160);
   s.floatText('+'+pts,{x:c.x,y:c.y+24},pts===3?'#ff0':Theme.green,24);c.run(A.sequence([A.scaleTo(1.35,.1),A.scaleTo(1,.1)]));if(!s.isCPU){Sfx.play(pts===3?'coin':'right');Haptic.good()}
   st.cells.forEach((o,i)=>{if(i!==idx)o.run(A.fadeTo(.25,.2))});if(this.seats.every(x=>this.states[x.index].done))this.endRound();else this.scheduleTimeout(4)}
  else{st.lock=1;s.shake(4);s.flash('#f00',.3);c.run(A.sequence([A.fadeTo(.15,.1),A.fadeTo(.4,.9)]));if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}}}
 scheduleTimeout(secs){if(this.timeoutArmed)return;this.timeoutArmed=true;const r=this.round;this.run(A.sequence([A.wait(secs),A.run(()=>{if(this.round!==r||this.waiting||this.phase!=='playing')return;this.endRound()})]))}
 endRound(){if(this.waiting)return;this.waiting=true;this.timeoutArmed=false;
  for(const s of this.seats){const st=this.states[s.index];if(!st.done)st.cells[st.odd].run(A.repeat(A.sequence([A.scaleTo(1.3,.12),A.scaleTo(1,.12)]),2))}
  const r=this.round;this.run(A.sequence([A.wait(.7),A.run(()=>{if(this.phase!=='playing'||this.round!==r)return;if(this.round>=ROUNDS)this.finishGame();else this.newRound()})]))}
 began(seat,at){const st=this.states[seat.index];let best=-1,bd=st.cell*.6;st.cells.forEach((c,i)=>{const d=Math.hypot(at.x-c.x,at.y-c.y);if(d<bd){bd=d;best=i}});if(best>=0)this.tap(seat,best)}
}
Arcade.register('oddone',OddOneGame);
})();
