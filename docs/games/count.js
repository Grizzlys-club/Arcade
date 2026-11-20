(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const ROUNDS=8,GREEN=rgba(.1,.8,.3),RED=rgba(.85,.12,.18);
class CountGame extends MiniScene{
 setupGame(){const s0=this.seats[0],w=s0.w,h=s0.h;this.puckR=Math.min(14,w*.06);const y0=-h/2+76,y1=h/2-54;this.areaC={x:0,y:(y0+y1)/2};this.areaS={w:w-28,h:y1-y0};this.btnY=-h/2+34;
  this.round=0;this.stp='intro';this.t=0;this.answerT=0;this.order=0;this.counts=[];this.options=[];this.unitPos=[];this.states=[];
  const r=this.newRand(),pr=this.puckR;
  for(let k=0;k<ROUNDS;k++){const n=r.int(3,9);this.counts.push(n);const cands=r.shuffled([n-2,n-1,n+1,n+2,n+3,n-3].filter(x=>x>=1)),opts=[n];while(opts.length<4&&cands.length)opts.push(cands.shift());this.options.push(opts.sort((a,b)=>a-b));
   const pts=[],minD=pr*2.3;for(let i=0;i<n;i++){let best={x:.5,y:.5},bestD=-1;for(let j=0;j<40;j++){const c={x:r.range(0,1),y:r.range(0,1)};let md=Infinity;for(const p of pts)md=Math.min(md,Math.hypot((p.x-c.x)*(this.areaS.w-2*pr),(p.y-c.y)*(this.areaS.h-2*pr)));if(md>bestD){bestD=md;best=c}if(md>=minD)break}pts.push(best)}this.unitPos.push(pts)}
  for(const s of this.seats){const st={pucks:[],buttons:[],answered:false,locked:false,cpuAt:0,cpuPick:0};
   for(let i=0;i<9;i++){const p=new Sprite(Gfx.circle(pr,white(.1)),pr*2,pr*2),ring=new Sprite(Gfx.circle(pr*.78,white(.1)),pr*1.56,pr*1.56);ring.color=Theme.blue;ring.cbf=.35;ring.z=1;p.add(ring);
    const g=new Sprite(Gfx.glow(),pr*4.2,pr*4.2);g.blend='add';g.color=Theme.blue;g.cbf=1;g.alpha=.6;g.z=-1;p.add(g);p.alpha=0;p.z=5;s.field.add(p);st.pucks.push(p)}
   const bw=(w-20-18)/4;for(let i=0;i<4;i++){const b=this.button('?',bw,44,s.color,'#fff',Math.min(22,w*.1));b.x=-w/2+10+bw/2+i*(bw+6);b.y=this.btnY;b.z=8;b.alpha=0;s.field.add(b);st.buttons.push(b)}
   st.status=label('',Math.min(13,w*.065),white(1,.85));st.status.y=h/2-40;st.status.z=6;s.field.add(st.status);
   st.big=label('',Math.min(90,w*.4),'#fff');st.big.x=this.areaC.x;st.big.y=this.areaC.y;st.big.z=12;st.big.alpha=0;s.field.add(st.big);this.states.push(st)}}
 gameStarted(){this.startRound()}
 startRound(){this.stp='intro';this.t=.8;this.order=0;const opts=this.options[this.round];
  for(const s of this.seats){const st=this.states[s.index];st.answered=false;st.locked=false;st.big.alpha=0;for(const p of st.pucks){p.removeAllActions();p.alpha=0}
   st.buttons.forEach((b,i)=>{b.removeAllActions();b.alpha=0;b.color=s.color;b.setScale(1);if(b.children[0])b.children[0].text=''+opts[i]});
   st.status.text=this.round===0?'ZÄHLE DIE PUCKS!':'RUNDE '+(this.round+1)+'/'+ROUNDS;
   if(s.isCPU){st.cpuAt=.5+(1-s.skill)*1.7+Math.random()*.6;const ci=Math.max(0,opts.indexOf(this.counts[this.round]));let pick=ci;
    if(Math.random()<.04+.42*Math.pow(1-s.skill,1.2)){const n=this.counts[this.round],near=[n-1,n+1].map(v=>opts.indexOf(v)).filter(i=>i>=0);
     if(near.length&&Math.random()<.8)pick=near[Math.floor(Math.random()*near.length)];else{const wr=[0,1,2,3].filter(i=>i!==ci);pick=wr[Math.floor(Math.random()*wr.length)]}}st.cpuPick=pick}}
  Sfx.play('tick')}
 pp(u){return{x:this.areaC.x+(u.x-.5)*(this.areaS.w-2*this.puckR),y:this.areaC.y+(u.y-.5)*(this.areaS.h-2*this.puckR)}}
 beginShow(){this.stp='show';this.t=1.2;const n=this.counts[this.round],pos=this.unitPos[this.round];
  for(const s of this.seats){const st=this.states[s.index];st.status.text='SCHAU GENAU!';for(let i=0;i<n;i++){const p=st.pucks[i],q=this.pp(pos[i]);p.x=q.x;p.y=q.y;p.setScale(.1);p.alpha=0;p.run(A.sequence([A.wait(i*.04),A.group([A.fadeIn(.08),A.scaleTo(1,.14)])]))}}
  Sfx.play('pop')}
 beginAnswer(){this.stp='answer';this.t=5;this.answerT=0;for(const s of this.seats){const st=this.states[s.index];st.status.text='WIE VIELE?';for(const p of st.pucks)p.run(A.fadeOut(.08));
   for(const b of st.buttons){b.setScale(.6);b.run(A.group([A.fadeTo(1,.1),A.scaleTo(1,.12)]))}}Sfx.play('beep')}
 beginReveal(){this.stp='reveal';this.t=1.5;const n=this.counts[this.round],opts=this.options[this.round],ci=Math.max(0,opts.indexOf(n)),pos=this.unitPos[this.round];
  for(const s of this.seats){const st=this.states[s.index];st.buttons[ci].color=GREEN;if(!st.answered&&!st.locked)st.status.text='ZU LANGSAM';st.big.text=''+n;st.big.setScale(1.5);st.big.alpha=0;st.big.run(A.group([A.fadeTo(.9,.15),A.scaleTo(1,.15)]));
   for(let i=0;i<n;i++){const p=st.pucks[i],q=this.pp(pos[i]);p.x=q.x;p.y=q.y;p.removeAllActions();p.setScale(1);p.run(A.fadeTo(.3,.15))}}}
 gameUpdate(dt){
  if(this.stp==='intro'){this.t-=dt;if(this.t<=0)this.beginShow()}
  else if(this.stp==='show'){this.t-=dt;if(this.t<=0)this.beginAnswer()}
  else if(this.stp==='answer'){this.t-=dt;this.answerT+=dt;for(const s of this.seats){if(!s.isCPU)continue;const st=this.states[s.index];if(!st.answered&&!st.locked&&this.answerT>=st.cpuAt)this.pick(s,st.cpuPick)}
   if(this.t<=0||this.seats.every(s=>this.states[s.index].answered||this.states[s.index].locked))this.beginReveal()}
  else{this.t-=dt;if(this.t<=0&&this.phase==='playing'){this.round++;if(this.round>=ROUNDS)this.finishGame();else this.startRound()}}}
 pick(s,idx){const st=this.states[s.index];if(this.stp!=='answer'||st.answered||st.locked)return;const b=st.buttons[idx];
  if(this.options[this.round][idx]===this.counts[this.round]){st.answered=true;this.order++;const pts=this.order===1?3:1;this.addScore(s,pts);this.addStat('quiz',1,s);b.color=GREEN;b.run(A.sequence([A.scaleTo(1.2,.07),A.scaleTo(1,.1)]));
   st.status.text=this.order===1?'SCHNELLSTER!':'RICHTIG!';s.floatText('+'+pts,{x:b.x,y:this.btnY+40},pts===3?'#ff0':'#fff',pts===3?30:24);s.burst({x:b.x,y:b.y},pts===3?'#ff0':s.color,pts===3?16:7,80);if(!s.isCPU){Sfx.play(pts===3?'coin':'right');Haptic.good()}}
  else{st.locked=true;b.color=RED;b.alpha=.7;st.status.text='FALSCH – GESPERRT';s.shake(4);if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}}}
 began(seat,at){if(this.stp!=='answer')return;if(at.y>this.btnY+44)return;const st=this.states[seat.index];let best=0,bd=Infinity;st.buttons.forEach((b,i)=>{const d=Math.abs(b.x-at.x);if(d<bd){bd=d;best=i}});this.pick(seat,best)}
}
Arcade.register('count',CountGame);
})();
