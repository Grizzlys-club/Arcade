(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const COLS=[rgba(1,.25,.3),rgba(.2,.6,1),rgba(.2,.95,.45),rgba(1,.85,.15)],ICONS=['▲','●','■','◆'],SOUNDS=['beep','pop','kick','bounce'];
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
class SimonGame extends MiniScene{
 setupGame(){this.rand=this.newRand();this.hasHumans=this.seats.some(s=>!s.isCPU);this.states=[];this.sequence=[];this.stp='pause';this.timer=0;this.showIndex=0;this.showLit=false;this.inputLeft=0;this.round=0;
  for(const s of this.seats){const st={pads:[],progress:0,done:false,cpuTimer:0},usableTop=s.h/2-40,usableBottom=-s.h/2+16,gap=10,side=Math.min((s.w-30-gap)/2,(usableTop-usableBottom-40-gap)/2),cy=(usableTop+usableBottom)/2-12;
   for(let i=0;i<4;i++){const col=i%2,row=Math.floor(i/2),x=(col-.5)*(side+gap),y=cy+(.5-row)*(side+gap),c=COLS[i];
    const glow=new Sprite(Gfx.glow(),side*1.9,side*1.9);glow.color=c;glow.cbf=1;glow.blend='add';glow.alpha=0;glow.x=x;glow.y=y;glow.z=4;s.field.add(glow);
    const node=new Sprite(Gfx.pill(side,side,alpha(c,.9),white(1,.7),side*.22),side,side);node.x=x;node.y=y;node.alpha=.35;node.z=5;s.field.add(node);
    const icon=label(ICONS[i],side*.42);icon.z=1;node.add(icon);st.pads.push({node,glow,x,y,side})}
   st.status=label('MERKEN!',Math.min(22,s.w*.1),'#fff');st.status.y=usableTop-4;st.status.z=10;s.field.add(st.status);this.states.push(st)}}
 gameStarted(){this.nextRound()}
 nextRound(){this.round++;this.sequence.push(this.rand.int(0,3));this.stp='pause';this.timer=.7;this.showIndex=0;this.showLit=false;
  for(const s of this.seats){if(!s.alive)continue;const st=this.states[s.index];st.progress=0;st.done=false;st.status.text='MERKEN! ('+this.sequence.length+')';st.status.color='#fff'}}
 get showInterval(){return Math.max(.28,.6-.025*this.sequence.length)}
 gameUpdate(dt){
  if(this.stp==='pause'){this.timer-=dt;if(this.timer<=0){this.stp='showing';this.timer=0;this.showIndex=0;this.showLit=false}}
  else if(this.stp==='showing'){this.timer-=dt;if(this.timer<=0){
    if(this.showLit){for(const s of this.seats)if(s.alive)this.setLit(s,this.sequence[this.showIndex],false);this.showLit=false;this.showIndex++;this.timer=this.showInterval*.45;if(this.showIndex>=this.sequence.length)this.beginInput()}
    else{const p=this.sequence[this.showIndex];for(const s of this.seats)if(s.alive)this.setLit(s,p,true);Sfx.play(SOUNDS[p]);this.showLit=true;this.timer=this.showInterval}}}
  else{this.inputLeft-=dt;
   for(const s of this.seats){if(!s.alive||!s.isCPU)continue;const st=this.states[s.index];if(st.done)continue;st.cpuTimer-=dt;
    if(st.cpuTimer<=0){st.cpuTimer=.32+(1-s.skill)*.4+Math.random()*.2;const len=this.sequence.length,mistake=Math.max(0,(len-(3+s.skill*9))*.07)+.015*(1-s.skill);let pad=this.sequence[st.progress];if(Math.random()<mistake)pad=(pad+1+Math.floor(Math.random()*3))%4;this.press(s,pad)}}
   if(this.inputLeft<=0){for(const s of this.seats)if(s.alive&&!this.states[s.index].done)this.fail(s,'ZU LANGSAM');this.endRound()}}
  if(this.elapsed>80&&this.stp!=='input')this.finishGame()}
 beginInput(){this.stp='input';this.inputLeft=2.5+this.sequence.length*.9;for(const s of this.seats){if(!s.alive)continue;const st=this.states[s.index];st.status.text='DU BIST DRAN!';st.status.color=s.color;st.cpuTimer=.5+Math.random()*.3}}
 setLit(s,p,on){const pad=this.states[s.index].pads[p];pad.node.removeAction('lit');pad.glow.removeAction('lit');
  if(on){pad.node.alpha=1;pad.node.run(A.scaleTo(1.07,.06),'lit');pad.glow.alpha=.85}else{pad.node.run(A.group([A.fadeTo(.35,.12),A.scaleTo(1,.12)]),'lit');pad.glow.run(A.fadeOut(.12),'lit')}}
 blink(s,p){this.setLit(s,p,true);const pad=this.states[s.index].pads[p];pad.node.run(A.sequence([A.wait(.16),A.run(()=>this.setLit(s,p,false))]),'blink')}
 press(s,p){if(this.stp!=='input'||!s.alive)return;const st=this.states[s.index];if(st.done)return;this.blink(s,p);
  if(this.sequence[st.progress]===p){if(!s.isCPU){Sfx.play(SOUNDS[p]);Haptic.tap()}st.progress++;
   if(st.progress>=this.sequence.length){st.done=true;this.setScore(s,this.sequence.length);st.status.text='✓ SUPER!';st.status.color=Theme.green;s.burst({x:0,y:0},s.color,12);if(!this.seats.some(x=>x.alive&&!this.states[x.index].done))this.endRound()}}
  else{this.fail(s,'FALSCH!');if(!this.seats.some(x=>x.alive&&!this.states[x.index].done))this.endRound()}}
 fail(s,text){const st=this.states[s.index];st.done=true;st.status.text=text;st.status.color='#f00';s.flash('#f00',.4);s.shake();if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}s.knockOut('RAUS')}
 endRound(){if(this.stp!=='input')return;this.stp='pause';const alive=this.aliveSeats.length,humansAlive=this.seats.some(s=>!s.isCPU&&s.alive);
  if((alive<=1&&this.n>1)||alive===0||(this.hasHumans&&!humansAlive)||this.elapsed>80){this.finishGame();return}
  Sfx.play('right');this.run(A.sequence([A.wait(.6),A.run(()=>this.nextRound())]));this.timer=100}
 began(seat,at){const st=this.states[seat.index];for(let i=0;i<4;i++){const p=st.pads[i];if(Math.abs(at.x-p.x)<=p.side/2+4&&Math.abs(at.y-p.y)<=p.side/2+4){this.press(seat,i);return}}}
}
Arcade.register('simon',SimonGame);
})();
