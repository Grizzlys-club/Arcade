(()=>{
const {Node,Sprite,Label,A,Gfx,Theme,rgba,white,label}=SK;
const ICONS=['stick','ball','glove','goal','trophy','LOGO'];
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
class MemoryGame extends MiniScene{
 setupGame(){this.duration=60;const r=this.newRand(),layout=r.shuffled([0,0,1,1,2,2,3,3,4,4,5,5]);this.states=[];this.finishOrder=[];
  const s0=this.seats[0],wide=s0.w>s0.h*.8,cols=wide?4:3,rows=12/cols,gap=8,top=s0.h/2-36,bottom=-s0.h/2+12,maxW=(s0.w-24-gap*(cols-1))/cols,maxH=(top-bottom-gap*(rows-1))/rows;
  let cw=maxW,ch=cw*1.25;if(ch>maxH){ch=maxH;cw=ch/1.25}this.cw=cw;this.ch=ch;const gridW=cw*cols+gap*(cols-1),gridH=ch*rows+gap*(rows-1),cy=(top+bottom)/2;
  for(const s of this.seats){const st={cards:[],first:null,pendingSecond:null,busy:0,pairs:0,finished:false,cpuTimer:0,memory:{}};
   for(let i=0;i<12;i++){const col=i%cols,row=Math.floor(i/cols),x=-gridW/2+cw/2+col*(cw+gap),y=cy+gridH/2-ch/2-row*(ch+gap);
    const node=new Sprite(null,cw,ch);node.x=x;node.y=y;node.z=5;s.field.add(node);
    const back=new Node(),bs=new Sprite(Gfx.pill(cw,ch,alpha(s.color,.55),white(1,.5),10),cw,ch);back.add(bs);const ls=Math.min(cw,ch)*.62,logo=new Sprite(Gfx.logo,ls,ls);logo.alpha=.55;logo.z=1;back.add(logo);node.add(back);
    const front=new Node(),fs=new Sprite(Gfx.pill(cw,ch,white(.95),s.color,10),cw,ch);front.add(fs);const pair=layout[i],icon=ICONS[pair];
    if(icon==='LOGO'){const l=new Sprite(Gfx.logo,ls*1.1,ls*1.1);l.z=1;front.add(l)}else{const l=NK.icon(icon,Math.min(cw,ch)*.78);l.z=1;front.add(l)}
    front.hidden=true;node.add(front);st.cards.push({node,front,back,pair,open:false,matched:false})}
   this.states.push(st)}}
 gameStarted(){for(const s of this.seats)if(s.isCPU)this.states[s.index].cpuTimer=.8+Math.random()*.4}
 flip(card,open){card.open=open;card.node.removeAction('flip');card.node.run(A.sequence([A.scaleXTo(0,.09),A.run(()=>{card.front.hidden=!open;card.back.hidden=open}),A.scaleXTo(1,.09)]),'flip')}
 gameUpdate(dt){for(const s of this.seats){const st=this.states[s.index];if(st.busy>0){st.busy-=dt;if(st.busy<=0)this.closeMismatch(s);continue}
   if(s.isCPU&&!st.finished){st.cpuTimer-=dt;if(st.cpuTimer<=0){st.cpuTimer=.55+(1-s.skill)*.6+Math.random()*.25;this.cpuMove(s)}}}
  if(this.seats.every(s=>this.states[s.index].finished)&&this.phase==='playing')this.finishGame()}
 cpuMove(s){const st=this.states[s.index],hidden=st.cards.map((_,i)=>i).filter(i=>!st.cards[i].matched&&!st.cards[i].open);if(!hidden.length)return;const remember=.45+s.skill*.5;
  const rnd=a=>a[Math.floor(Math.random()*a.length)],unknownPick=()=>{const u=hidden.filter(i=>st.memory[i]==null);return rnd(u.length?u:hidden)};
  if(st.first!=null){const pair=st.cards[st.first].pair;let known=null;for(const k of Object.keys(st.memory)){const ki=+k;if(st.memory[k]===pair&&ki!==st.first&&hidden.includes(ki)){known=ki;break}}
   if(known!=null&&Math.random()<remember)this.pick(s,known);else this.pick(s,unknownPick())}
  else{let pp=null;for(const k of Object.keys(st.memory)){const i=+k,p=st.memory[k];if(!hidden.includes(i))continue;if(Object.keys(st.memory).some(k2=>+k2!==i&&st.memory[k2]===p&&hidden.includes(+k2))){pp=i;break}}
   if(pp!=null&&Math.random()<remember)this.pick(s,pp);else this.pick(s,unknownPick())}}
 pick(s,i){const st=this.states[s.index];if(st.finished||st.busy>0)return;const card=st.cards[i];if(card.open||card.matched)return;this.flip(card,true);st.memory[i]=card.pair;if(!s.isCPU){Sfx.play('tap');Haptic.tap()}
  if(st.first!=null){const f=st.first,other=st.cards[f];st.first=null;
   if(other.pair===card.pair){other.matched=true;card.matched=true;delete st.memory[f];delete st.memory[i];st.pairs++;this.addScore(s,10);this.addStat('hits',1,s);
    for(const c of[other,card]){c.node.run(A.sequence([A.wait(.18),A.scaleTo(1.15,.08),A.scaleTo(1,.1),A.fadeTo(.55,.2)]));s.burst({x:c.node.x,y:c.node.y},s.color,8,70)}
    if(!s.isCPU){Sfx.play('right');Haptic.good()}
    if(st.pairs>=6){st.finished=true;this.finishOrder.push(s.index);const place=this.finishOrder.length,bonus=[30,20,10,0][Math.min(3,place-1)];this.addScore(s,bonus);
     s.banner(place===1?'ERSTER!':place+'. PLATZ',place===1?'#ff0':s.color,36,1.2);if(bonus>0)s.floatText('+'+bonus+' BONUS',{x:0,y:-50},'#ff0',22);if(!s.isCPU)Sfx.play('fanfare')}}
   else{st.busy=.75;st.first=f;st.pendingSecond=i}}
  else st.first=i}
 closeMismatch(s){const st=this.states[s.index];if(st.first!=null&&st.pendingSecond!=null){this.flip(st.cards[st.first],false);this.flip(st.cards[st.pendingSecond],false);if(!s.isCPU)Sfx.play('miss')}st.first=null;st.pendingSecond=null}
 began(seat,at){const st=this.states[seat.index];for(let i=0;i<st.cards.length;i++){const c=st.cards[i].node;if(Math.abs(at.x-c.x)<=this.cw/2+3&&Math.abs(at.y-c.y)<=this.ch/2+3){this.pick(seat,i);return}}}
}
Arcade.register('memory',MemoryGame);
})();
