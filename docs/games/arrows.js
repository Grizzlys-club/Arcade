(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const COLORS=[rgba(.2,.95,1),rgba(1,.3,.75),rgba(.6,1,.25),rgba(1,.8,.1)];
const ANG=[0,-Math.PI/2,Math.PI,Math.PI/2];
const VEC=[{dx:0,dy:1},{dx:1,dy:0},{dx:0,dy:-1},{dx:-1,dy:0}];
class ArrowsGame extends MiniScene{
 static arrowTexture(sz){return Gfx.texture('arrows_arrow_'+Math.floor(sz),sz,sz,2,c=>{const s=sz;c.fillStyle='#fff';c.beginPath();c.moveTo(s*.5,s*.02);c.lineTo(s*.96,s*.5);c.lineTo(s*.68,s*.5);c.lineTo(s*.68,s*.98);c.lineTo(s*.32,s*.98);c.lineTo(s*.32,s*.5);c.lineTo(s*.04,s*.5);c.closePath();c.fill()})}
 setupGame(){this.duration=30;this.states=[];
  for(const s of this.seats){const st={rand:this.newRand(),dir:0,streak:0,start:null,touch:null,cpuTimer:0};
   const sz=Math.min(s.w-50,(s.h-100)*.9,190);st.arrowSize=sz;const cy=(s.h/2-40+(-s.h/2+10))/2;
   const ring=new Sprite(Gfx.pill(s.w-24,s.h-80,white(.05,.7),white(1,.2),22),s.w-24,s.h-80);ring.y=cy;ring.z=1;s.field.add(ring);
   const node=new Node();node.y=cy;node.z=4;const g=new Sprite(Gfx.glow(),sz*1.8,sz*1.8);g.blend='add';g.alpha=.8;node.add(g);st.glow=g;
   const a=new Sprite(ArrowsGame.arrowTexture(sz),sz,sz);a.name='a';node.add(a);st.a=a;s.field.add(node);st.arrow=node;
   const sl=label('',14,'#ff0');sl.y=cy-(s.h-80)/2+14;sl.z=6;s.field.add(sl);st.streakLabel=sl;
   const hint=label('WISCHEN ↑ → ↓ ←',Math.min(18,s.w*.075),'#fff');hint.y=cy+(s.h-80)/2-20;hint.z=7;s.field.add(hint);hint.run(A.sequence([A.wait(3.5),A.fadeOut(.5)]));
   node.alpha=.3;this.states.push(st)}}
 gameStarted(){for(const s of this.seats)this.nextArrow(s)}
 nextArrow(s){const st=this.states[s.index];let d=st.rand.int(0,3);if(d===st.dir&&st.rand.chance(.4))d=(d+1+st.rand.int(0,2))%4;st.dir=d;
  const col=COLORS[st.rand.int(0,3)];st.arrow.alpha=1;st.arrow.rot=ANG[d];st.a.color=col;st.a.cbf=1;st.glow.color=col;st.glow.cbf=1;
  st.arrow.setScale(.8);st.arrow.run(A.scaleTo(1,.08));if(s.isCPU)st.cpuTimer=.35+(1-s.skill)*.7+Math.random()*.15}
 gameUpdate(dt){for(const s of this.seats){if(!s.isCPU)continue;const st=this.states[s.index];st.cpuTimer-=dt;
  if(st.cpuTimer<=0){const ok=Math.random()<.62+s.skill*.34;this.answer(s,ok?st.dir:(st.dir+1+Math.floor(Math.random()*3))%4)}}}
 answer(s,dir){const st=this.states[s.index],off=VEC[dir],pos={x:st.arrow.x,y:st.arrow.y};
  if(dir===st.dir){st.streak++;const bonus=st.streak%8===0;this.addScore(s,bonus?2:1);this.addStat('hits',1,s);s.burst(pos,'#fff',6,150);
   s.floatText(bonus?'+2 SERIE!':'+1',{x:pos.x+off.dx*30,y:pos.y+st.arrowSize*.55},bonus?'#ff0':Theme.green,bonus?24:20);
   st.streakLabel.text=st.streak>=4?'🔥 '+st.streak+'er Serie':'';if(!s.isCPU){Sfx.play(bonus?'coin':'tap');Haptic.tap()}this.nextArrow(s)}
  else{st.streak=0;st.streakLabel.text='';this.setScore(s,Math.max(0,s.score-1));s.flash('#f00',.35);s.shake(6);s.floatText('−1',{x:pos.x,y:pos.y+st.arrowSize*.55},'#f33',22);
   st.arrow.run(A.sequence([A.moveBy(10,0,.03),A.moveBy(-20,0,.05),A.moveBy(10,0,.03)]));if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}if(s.isCPU)st.cpuTimer=.4+(1-s.skill)*.4}}
 began(seat,at,id){const st=this.states[seat.index];st.start=at;st.touch=id}
 moved(seat,at,id){const st=this.states[seat.index];if(st.touch!==id||!st.start)return;const dx=at.x-st.start.x,dy=at.y-st.start.y;if(Math.hypot(dx,dy)<=26)return;st.start=null;
  this.answer(seat,Math.abs(dx)>Math.abs(dy)?(dx>0?1:3):(dy>0?0:2))}
 ended(seat,at,id){const st=this.states[seat.index];if(st.touch===id){st.start=null;st.touch=null}}
}
Arcade.register('arrows',ArrowsGame);
})();
